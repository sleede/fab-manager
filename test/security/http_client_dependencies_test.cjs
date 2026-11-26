/* eslint-env node */
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const axios = require('axios');
const FormData = require('form-data');
const redirectHttp = require('follow-redirects').http;

async function listen (handler) {
  const server = http.createServer(handler);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  return { server, url: 'http://127.0.0.1:' + server.address().port };
}

async function close (server) {
  server.closeAllConnections();
  await new Promise(resolve => server.close(resolve));
}

test('ignores inherited request methods without changing own configuration', async () => {
  const endpoint = await listen((req, res) => res.end(req.method));
  const descriptor = Object.getOwnPropertyDescriptor(Object.prototype, 'method');
  try {
    // eslint-disable-next-line no-extend-native -- Bounded prototype-gadget probe; the descriptor is restored in finally.
    Object.defineProperty(Object.prototype, 'method', { configurable: true, value: 'POST', writable: true });
    const response = await axios.request({ url: endpoint.url, proxy: false });
    assert.equal(response.data, 'GET');
    const own = await axios.request({ url: endpoint.url, method: 'PUT', proxy: false });
    assert.equal(own.data, 'PUT');
  } finally {
    // eslint-disable-next-line no-extend-native -- Restore the exact original descriptor after the probe.
    if (descriptor) Object.defineProperty(Object.prototype, 'method', descriptor);
    else delete Object.prototype.method;
    await close(endpoint.server);
  }
});

test('does not forward credentials across a redirect to a different origin', async () => {
  let received;
  const target = await listen((req, res) => { received = req.headers; res.end('local target'); });
  const source = await listen((req, res) => { res.writeHead(302, { Location: target.url }); res.end(); });
  try {
    await axios.get(source.url, { proxy: false, headers: { Authorization: 'Bearer local-fixture', Cookie: 'review=fixture' } });
    assert.equal(received.authorization, undefined);
    assert.equal(received.cookie, undefined);
  } finally {
    await close(source.server);
    await close(target.server);
  }
});

test('routes an explicit HTTP proxy locally and rejects invalid proxy protocols', async () => {
  const proxy = await listen((req, res) => res.end(req.url));
  const port = proxy.server.address().port;
  try {
    const response = await axios.get('http://review.invalid/path?q=a%26b', { proxy: { host: '127.0.0.1', port, protocol: 'http:' } });
    assert.equal(response.data, 'http://review.invalid/path?q=a%26b');
    await assert.rejects(axios.get('http://review.invalid/', { proxy: { host: '127.0.0.1', port, protocol: 'invalid:' } }));
  } finally {
    await close(proxy.server);
  }
});

test('keeps multipart bodies, bounded limits and downloads intact', async () => {
  let body = '';
  const endpoint = await listen((req, res) => {
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => { res.setHeader('Content-Type', 'application/octet-stream'); res.end(Buffer.from([0, 65, 255])); });
  });
  try {
    const form = new FormData();
    form.append('file', Buffer.from('local multipart fixture'), { filename: 'review.txt', contentType: 'text/plain' });
    const response = await axios.post(endpoint.url, form, { proxy: false, headers: form.getHeaders(), responseType: 'arraybuffer' });
    assert.match(body, /filename="review.txt"/);
    assert.match(body, /local multipart fixture/);
    assert.deepEqual(Buffer.from(response.data), Buffer.from([0, 65, 255]));
    await assert.rejects(axios.post(endpoint.url, 'x'.repeat(65), { proxy: false, maxBodyLength: 32 }));
  } finally {
    await close(endpoint.server);
  }
});

test('bounds response time without changing timeout errors', async () => {
  const endpoint = await listen((req, res) => setTimeout(() => res.end('late'), 80));
  try {
    await assert.rejects(axios.get(endpoint.url, { proxy: false, timeout: 10 }), /timeout/i);
  } finally {
    await close(endpoint.server);
  }
});

test('honors explicitly sensitive custom headers in the redirect driver', async () => {
  let received;
  const target = await listen((req, res) => { received = req.headers; res.end('local target'); });
  const source = await listen((req, res) => { res.writeHead(302, { Location: target.url }); res.end(); });
  try {
    await new Promise((resolve, reject) => {
      redirectHttp.get(source.url, { headers: { 'X-API-Key': 'local-api-fixture' }, sensitiveHeaders: ['X-API-Key'] }, response => { response.resume(); response.on('end', resolve); }).on('error', reject);
    });
    assert.equal(received['x-api-key'], undefined);
  } finally {
    await close(source.server);
    await close(target.server);
  }
});
