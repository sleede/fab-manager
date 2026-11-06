// Local dependency contracts for the Node tooling used by Jest and Shakapacker.
// Run with the repository's Node version: yarn test:dependencies
const test = require('node:test');
const assert = require('node:assert/strict');
const { once } = require('node:events');
const { createRequire } = require('node:module');
const { dirname } = require('node:path');
const lodash = require('lodash');
const underscore = require('underscore');
const minimatch = require('minimatch');
const expand = require('brace-expansion');
const braces = require('braces');
const micromatch = require('micromatch');
const picomatch = require('picomatch');
const spawn = require('cross-spawn');

test('lodash preserves prototypes when given array-wrapped path segments', () => {
  const prototype = { protectedValue: 'keep' };
  const object = Object.create(prototype);

  lodash.unset(object, [['__proto__'], ['protectedValue']]);

  assert.equal(prototype.protectedValue, 'keep');
  assert.deepEqual(lodash.omit({ name: 'local', privateValue: 'hidden' }, ['privateValue']), { name: 'local' });
});

test('lodash rejects template import names that are not identifiers', () => {
  assert.throws(() => lodash.template('<%= local %>', { imports: { 'local = 1': 2 } }));
  assert.equal(lodash.template('<%- member %>')({ member: '<local>' }), '&lt;local&gt;');
});

test('underscore handles nested collections without changing ordinary results', () => {
  let nested = 'local';
  for (let i = 0; i < 4500; i++) nested = [nested];

  assert.deepEqual(underscore.flatten(nested), ['local']);
  assert.equal(underscore.isEqual({ values: [1, 2] }, { values: [1, 2] }), true);
  assert.equal(underscore.isEqual({ values: [1, 2] }, { values: [1, 3] }), false);
});

test('glob libraries preserve the frontend source selection rules', () => {
  const sources = ['app/frontend/card.tsx', 'app/frontend/style.scss', 'app/frontend/.private.tsx'];
  const pattern = 'app/frontend/**/*.{ts,tsx}';

  assert.deepEqual(sources.filter(file => minimatch(file, pattern)), ['app/frontend/card.tsx']);
  assert.deepEqual(micromatch(sources, pattern), ['app/frontend/card.tsx']);
  assert.deepEqual(expand('part{01..03}.js'), ['part01.js', 'part02.js', 'part03.js']);
  assert.deepEqual(braces.expand('part{a,b}.js'), ['parta.js', 'partb.js']);
});

test('picomatch does not treat inherited properties as POSIX classes', () => {
  assert.equal(picomatch('[[:constructor:]]')('f'), false);
  assert.equal(picomatch('[[:alpha:]]')('f'), true);
});

test('cross-spawn preserves arguments without invoking a shell', () => {
  const value = 'local value with & spaces';
  const result = spawn.sync(process.execPath, ['-e', 'process.stdout.write(process.argv[1])', value],
    { encoding: 'utf8', timeout: 2000 });

  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, value);
});

const jsdomRequire = createRequire(require.resolve('jsdom/package.json'));
const FormData = jsdomRequire('form-data');

test('form-data preserves multipart values and escapes field and filename delimiters', () => {
  const form = new FormData();
  form.append('caption"\r\nX-Local-Test: injected', 'local value');
  form.append('file', Buffer.from('local file'), { filename: 'sample"\r\nX-Local-Test: injected.txt' });
  const body = form.getBuffer().toString('utf8');

  assert.match(body, /name="caption%22%0D%0AX-Local-Test: injected"/);
  assert.match(body, /filename="sample%22%0D%0AX-Local-Test: injected\.txt"/);
  assert.equal(body.includes('\r\nX-Local-Test: injected'), false);
  assert.ok(body.includes('local value'));
  assert.ok(body.includes('local file'));
  assert.match(form.getHeaders()['content-type'], /^multipart\/form-data; boundary=/);
});

const wsPaths = [...new Set(['jsdom', 'webpack-dev-server'].map(parent => {
  const parentRequire = createRequire(require.resolve(parent + '/package.json'));
  return parentRequire.resolve('ws');
}))];

for (const wsPath of wsPaths) {
  const WebSocket = require(wsPath);
  test('WebSocket echo and payload limits through ' + dirname(wsPath), { timeout: 5000 }, async () => {
    const server = new WebSocket.Server({ host: '127.0.0.1', port: 0, maxPayload: 64 });
    let client;
    try {
      await once(server, 'listening');
      const serverError = new Promise(resolve => {
        server.on('connection', socket => {
          socket.on('error', resolve);
          socket.on('message', (data, isBinary) => socket.send(data, { binary: isBinary }));
        });
      });
      client = new WebSocket('ws://127.0.0.1:' + server.address().port);
      await once(client, 'open');
      const echoed = once(client, 'message');
      client.send('local');
      assert.equal((await echoed)[0].toString(), 'local');

      const closed = once(client, 'close');
      client.send(Buffer.alloc(65));
      assert.equal((await closed)[0], 1009);
      assert.equal((await serverError).code, 'WS_ERR_UNSUPPORTED_MESSAGE_LENGTH');
    } finally {
      if (client && client.readyState !== WebSocket.CLOSED) client.terminate();
      for (const socket of server.clients) socket.terminate();
      await new Promise(resolve => server.close(resolve));
    }
  });
}
