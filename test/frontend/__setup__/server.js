import { setupServer } from 'msw/node';
import { rest } from 'msw';
import { buildHistoryItem } from '../__fixtures__/settings';
import FixturesLib from '../__lib__/fixtures';

let fixtures = null;

export const server = setupServer(
  rest.get('/api/groups', (req, res, ctx) => {
    return res(ctx.json(fixtures.groups));
  }),
  rest.get('/api/plan_categories', (req, res, ctx) => {
    return res(ctx.json(fixtures.planCategories));
  }),
  rest.get('/api/users', (req, res, ctx) => {
    switch (new URLSearchParams(req.url.search).get('role')) {
      case 'partner':
        return res(ctx.json(fixtures.partners));
      case 'manager':
        return res(ctx.json(fixtures.managers));
      default:
        return res(ctx.json(fixtures.users));
    }
  }),
  rest.get('/api/plans', (req, res, ctx) => {
    return res(ctx.json(fixtures.plans));
  }),
  rest.post('/api/plans', (req, res, ctx) => {
    return res(ctx.json(req.body));
  }),
  rest.put('/api/plans/:id', (req, res, ctx) => {
    return res(ctx.json(req.body));
  }),
  rest.post('/api/users', (req, res, ctx) => {
    /* eslint-disable camelcase */
    const { user: { first_name, last_name, email } } = req.body;
    return res(ctx.status(201), ctx.json({
      id: Math.ceil(Math.random() * 100),
      email,
      profile_attributes: { first_name, last_name }
    }));
    /* eslint-enable camelcase */
  }),
  rest.get('/api/settings/:name', (req, res, ctx) => {
    const setting = fixtures.settings.find(s => s.name === req.params.name);
    const history = new URLSearchParams(req.url.search).get('history');
    const result = { setting };
    if (history) {
      result.setting.history = [buildHistoryItem(setting)];
    }
    return res(ctx.json(result));
  }),
  rest.get('/api/settings', (req, res, ctx) => {
    const names = new URLSearchParams(req.url.search).get('names');
    const foundSettings = fixtures.settings.filter(setting => names.replace(/[[\]']/g, '').split(',').includes(setting.name));
    return res(ctx.json(Object.fromEntries(foundSettings.map(s => [s.name, s.value]))));
  }),
  rest.patch('/api/settings/bulk_update', (req, res, ctx) => {
    return res(ctx.json(req.body));
  }),
  rest.get('/api/product_categories', (req, res, ctx) => {
    return res(ctx.json(fixtures.productCategories));
  }),
  rest.get('/api/products', (req, res, ctx) => {
    return res(ctx.json(fixtures.products));
  }),
  rest.get('/api/products/:id/stock_movements', (req, res, ctx) => {
    const { id } = req.params;
    return res(ctx.json({
      page: 1,
      total_pages: Math.ceil(fixtures.productStockMovements.length / 10),
      page_size: 10,
      total_count: fixtures.productStockMovements.length,
      data: fixtures.productStockMovements.filter(m => String(m.product_id) === id)
    }));
  }),
  rest.get('/api/machines', (req, res, ctx) => {
    return res(ctx.json(fixtures.machines));
  }),
  rest.get('/api/auth_providers/active', (req, res, ctx) => {
    return res(ctx.json(fixtures.providers[0]));
  }),
  rest.get('/api/profile_custom_fields', (req, res, ctx) => {
    return res(ctx.json(fixtures.profileCustomFields));
  }),
  rest.get('/api/members/current', (req, res, ctx) => {
    return res(ctx.json(global.loggedUser));
  }),
  rest.get('/api/spaces', (req, res, ctx) => {
    return res(ctx.json(fixtures.spaces));
  }),
  rest.get('/api/statuses', (req, res, ctx) => {
    return res(ctx.json(fixtures.statuses));
  }),
  rest.delete('api/statuses/:id', (req, res, ctx) => {
    const id = parseInt(req.params.id);
    const statusIndex = fixtures.statuses.findIndex((status) => status.id === id);
    fixtures.statuses.splice(statusIndex, 1);
    return res(ctx.json());
  }),
  rest.patch('api/statuses/:id', async (req, res, ctx) => {
    const id = parseInt(req.params.id);
    const reqBody = await req.json();
    const status = fixtures.statuses.find((status) => status.id === id);
    status.label = reqBody.status.label;
    return res(ctx.json(status));
  }),
  rest.post('/api/statuses', async (req, res, ctx) => {
    const reqBody = await req.json();
    const status = reqBody.status;
    status.id = fixtures.statuses.length + 1;
    fixtures.statuses.push(status);
    return res(ctx.json({ status }));
  })
);

beforeAll(() => {
  server.listen();
  fixtures = FixturesLib.init();
}
);
afterEach(() => {
  server.resetHandlers();
  fixtures = FixturesLib.init();
});
afterAll(() => server.close());
