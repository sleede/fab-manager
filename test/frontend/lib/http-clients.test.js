import axios from 'axios';
import { rest } from 'msw';
import { server } from '../__setup__/server';
import ssoClient from 'api/clients/sso-client';
import stripeClient from 'api/clients/stripe-client';

const meta = document.createElement('meta');
meta.name = 'csrf-token';
meta.content = 'local-review-csrf';
document.head.appendChild(meta);
const apiClient = require('api/clients/api-client').default;
const Authentication = require('api/authentication').default;

describe('application HTTP clients', () => {
  afterAll(() => meta.remove());
  afterEach(() => {
    document.cookie = 'review_session=; max-age=0; path=/';
    document.cookie = 'XSRF-TOKEN=; max-age=0; path=/';
  });

  test('sends JSON and derives CSRF headers from the meta tag and browser cookie', async () => {
    document.cookie = 'review_session=fixture; path=/';
    document.cookie = 'XSRF-TOKEN=local-cookie-csrf; path=/';
    let received;
    server.use(rest.post('/api/review', (req, res, ctx) => {
      received = { body: req.body, csrf: req.headers.get('x-csrf-token'), xsrf: req.headers.get('x-xsrf-token') };
      return res(ctx.status(201), ctx.json({ id: 7 }));
    }));

    const response = await apiClient.post('/api/review', { title: 'Local & bounded' });

    expect(response.status).toBe(201);
    expect(response.data).toEqual({ id: 7 });
    expect(received).toEqual({ body: { title: 'Local & bounded' }, csrf: 'local-review-csrf', xsrf: 'local-cookie-csrf' });
    document.cookie = 'review_session=; max-age=0; path=/';
    document.cookie = 'XSRF-TOKEN=; max-age=0; path=/';
  });

  test('wraps direct login credentials for Devise and keeps logout and password verification', async () => {
    let payload;
    server.use(
      rest.post('/users/sign_in.json', (req, res, ctx) => {
        payload = req.body;
        if (!req.body.user?.email || !req.body.user?.password) return res(ctx.status(401), ctx.json({ error: 'Missing user credentials' }));
        return res(ctx.json({ id: 2 }));
      }),
      rest.delete('/users/sign_out.json', (req, res, ctx) => res(ctx.status(204))),
      rest.post('/password/verify.json', (req, res, ctx) => res(ctx.status(200)))
    );

    expect(await Authentication.login('member@example.test', 'Local-password-123!')).toEqual({ id: 2 });
    expect(payload).toEqual({ user: { email: 'member@example.test', password: 'Local-password-123!' } });
    expect(await Authentication.verifyPassword('Local-password-123!')).toBe(true);
    expect((await Authentication.logout()).status).toBe(204);
  });

  test('keeps the existing 304 response-interceptor contract', async () => {
    server.use(rest.get('/api/review', (req, res, ctx) => res(ctx.status(304))));
    expect((await apiClient.get('/api/review')).status).toBe(304);
  });

  test('keeps Rails validation and HTML errors readable', async () => {
    server.use(
      rest.get('/api/review-invalid', (req, res, ctx) => res(ctx.status(422), ctx.json({ name: ['is invalid'] }))),
      rest.get('/api/review-error', (req, res, ctx) => res(ctx.status(500), ctx.set('Content-Type', 'text/html'), ctx.body('<!DOCTYPE html><h1>Local error</h1>')))
    );
    await expect(apiClient.get('/api/review-invalid')).rejects.toBe('name : is invalid');
    await expect(apiClient.get('/api/review-error')).rejects.toBe('Local error');
  });

  test('isolates the Stripe bearer header from the SSO and application clients', async () => {
    const received = [];
    server.use(
      rest.get('https://api.stripe.com/v1/charges', (req, res, ctx) => {
        received.push({ path: req.url.pathname, auth: req.headers.get('authorization'), csrf: req.headers.get('x-csrf-token') });
        return res(ctx.json({ data: [] }));
      }),
      rest.get('https://identity.example.test/.well-known/openid-configuration', (req, res, ctx) => {
        received.push({ path: req.url.pathname, auth: req.headers.get('authorization'), csrf: req.headers.get('x-csrf-token') });
        return res(ctx.json({ issuer: 'https://identity.example.test' }));
      })
    );

    await stripeClient('local-fixture-key').get('charges');
    await ssoClient('https://identity.example.test/').get('.well-known/openid-configuration');

    expect(received).toEqual([
      { path: '/v1/charges', auth: 'Bearer local-fixture-key', csrf: null },
      { path: '/.well-known/openid-configuration', auth: null, csrf: null }
    ]);
    expect(apiClient.defaults.headers.common.Authorization).toBeUndefined();
  });

  test('preserves relative/absolute URL and query encoding contracts', () => {
    expect(stripeClient('local-fixture-key').getUri({ url: 'charges' })).toBe('https://api.stripe.com/v1/charges');
    expect(ssoClient('https://identity.example.test').getUri({ url: '/keys' })).toBe('https://identity.example.test/keys');
    const uri = apiClient.getUri({ url: 'http://localhost/api/review', params: { query: 'a&b', empty: '' } });
    expect(new URL(uri).searchParams.get('query')).toBe('a&b');
    expect(new URL(uri).searchParams.get('empty')).toBe('');
  });

  test('passes native FormData through the browser adapter', async () => {
    server.use(
      rest.post('/api/review-upload', (req, res, ctx) => {
        return res(ctx.json({ stored: true }));
      })
    );
    const form = new window.FormData();
    form.append('file', new window.File(['local fixture'], 'review.txt', { type: 'text/plain' }));
    const uploaded = await apiClient.post('/api/review-upload', form);
    expect(uploaded.data).toEqual({ stored: true });
    expect(uploaded.config.data).toBe(form);
  });

  test('preserves cancellation error handling at the client boundary', async () => {
    server.use(rest.get('/api/review-slow', (req, res, ctx) => res(ctx.delay(80), ctx.json({ ok: true }))));
    const cancellation = axios.CancelToken.source();
    const request = apiClient.get('/api/review-slow', { cancelToken: cancellation.token });
    cancellation.cancel('Local cancellation');
    await expect(request).rejects.toBe('Local cancellation');
  });

  test('passes explicit credential settings through the actual XHR adapter', async () => {
    const received = [];
    server.use(rest.get('https://identity.example.test/credentials', (req, res, ctx) => {
      received.push(req.credentials);
      return res(ctx.json({ ok: true }));
    }));
    const client = ssoClient('https://identity.example.test');
    await client.get('/credentials', { withCredentials: true });
    await client.get('/credentials', { withCredentials: false });
    expect(received).toEqual(['include', 'omit']);
  });
});
