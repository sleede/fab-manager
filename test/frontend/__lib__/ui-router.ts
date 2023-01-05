import { UIRouter } from '@uirouter/angularjs';

export const uiRouter = {
  $id: 0,
  _disposed: false,
  _disposables: [],
  _plugins: [],
  locationService: {},
  locationConfig: {},
  trace: {},
  globals: {
    current: { name: '' }
  },
  viewService: {},
  transitionService: {
    onBefore: () => jest.fn()
  },
  urlMatcherFactory: {},
  urlRouter: {},
  urlRouterProvider: {},
  urlService: {},
  stateRegistry: {},
  stateService: {},
  stateProvider: {},
  disposable: jest.fn(),
  dispose: jest.fn(),
  plugin: jest.fn(),
  getPlugin: jest.fn()
} as unknown as UIRouter;
