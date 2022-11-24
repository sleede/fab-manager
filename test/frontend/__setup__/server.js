import { setupServer } from 'msw/node';
import { rest } from 'msw';
import groups from '../__fixtures__/groups';
import plans from '../__fixtures__/plans';
import planCategories from '../__fixtures__/plan_categories';
import { partners } from '../__fixtures__/users';
import { setting, settings } from '../__fixtures__/settings';

const server = setupServer(
  rest.get('/api/groups', (req, res, ctx) => {
    return res(ctx.json(groups));
  }),
  rest.get('/api/plan_categories', (req, res, ctx) => {
    return res(ctx.json(planCategories));
  }),
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json(partners));
  }),
  rest.get('/api/plans', (req, res, ctx) => {
    return res(ctx.json(plans));
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
    return res(ctx.json(setting(req.params.name, 'true')));
  }),
  rest.get('/api/settings', (req, res, ctx) => {
    const { names } = req.params;
    return res(ctx.json(settings(names.replace(/[[\]']/g, '').split(','))));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
