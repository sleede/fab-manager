import { setupServer } from 'msw/node';
import { rest } from 'msw';
import groups from '../__fixtures__/groups';
import plans from '../__fixtures__/plans';
import planCategories from '../__fixtures__/plan_categories';
import { partners, managers, users } from '../__fixtures__/users';
import { buildHistoryItem, settings } from '../__fixtures__/settings';
import products from '../__fixtures__/products';
import productCategories from '../__fixtures__/product_categories';
import productStockMovements from '../__fixtures__/product_stock_movements';
import machines from '../__fixtures__/machines';
import providers from '../__fixtures__/auth_providers';
import profileCustomFields from '../__fixtures__/profile_custom_fields';
import spaces from '../__fixtures__/spaces';
import statuses from '../__fixtures__/statuses';

export const server = setupServer(
  rest.get('/api/groups', (req, res, ctx) => {
    return res(ctx.json(groups));
  }),
  rest.get('/api/plan_categories', (req, res, ctx) => {
    return res(ctx.json(planCategories));
  }),
  rest.get('/api/users', (req, res, ctx) => {
    switch (new URLSearchParams(req.url.search).get('role')) {
      case 'partner':
        return res(ctx.json(partners));
      case 'manager':
        return res(ctx.json(managers));
      default:
        return res(ctx.json(users));
    }
  }),
  rest.get('/api/plans', (req, res, ctx) => {
    return res(ctx.json(plans));
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
    const setting = settings.find(s => s.name === req.params.name);
    const history = new URLSearchParams(req.url.search).get('history');
    const result = { setting };
    if (history) {
      result.setting.history = [buildHistoryItem(setting)];
    }
    return res(ctx.json(result));
  }),
  rest.get('/api/settings', (req, res, ctx) => {
    const names = new URLSearchParams(req.url.search).get('names');
    const foundSettings = settings.filter(setting => names.replace(/[[\]']/g, '').split(',').includes(setting.name));
    return res(ctx.json(Object.fromEntries(foundSettings.map(s => [s.name, s.value]))));
  }),
  rest.patch('/api/settings/bulk_update', (req, res, ctx) => {
    return res(ctx.json(req.body));
  }),
  rest.get('/api/product_categories', (req, res, ctx) => {
    return res(ctx.json(productCategories));
  }),
  rest.get('/api/products', (req, res, ctx) => {
    return res(ctx.json(products));
  }),
  rest.get('/api/products/:id/stock_movements', (req, res, ctx) => {
    const { id } = req.params;
    return res(ctx.json({
      page: 1,
      total_pages: Math.ceil(productStockMovements.length / 10),
      page_size: 10,
      total_count: productStockMovements.length,
      data: productStockMovements.filter(m => String(m.product_id) === id)
    }));
  }),
  rest.get('/api/machines', (req, res, ctx) => {
    return res(ctx.json(machines));
  }),
  rest.get('/api/auth_providers/active', (req, res, ctx) => {
    return res(ctx.json(providers[0]));
  }),
  rest.get('/api/profile_custom_fields', (req, res, ctx) => {
    return res(ctx.json(profileCustomFields));
  }),
  rest.get('/api/members/current', (req, res, ctx) => {
    return res(ctx.json(global.loggedUser));
  }),
  rest.get('/api/spaces', (req, res, ctx) => {
    return res(ctx.json(spaces));
  }),
  rest.get('/api/statuses', (req, res, ctx) => {
    return res(ctx.json(statuses));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
