module.exports = function (api) {
  const validEnv = ['development', 'test', 'production'];
  const currentEnv = api.env();
  const isDevelopmentEnv = api.env('development');
  const isProductionEnv = api.env('production');
  const isTestEnv = api.env('test');

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      'Please specify a valid `NODE_ENV` or ' +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(currentEnv) +
        '.'
    );
  }

  const defaultConfigFunc = require('shakapacker/package/babel/preset.js');
  const resultConfig = defaultConfigFunc(api);

  const changesOnDefault = {
    presets: [
      [
        '@babel/preset-react',
        {
          development: isDevelopmentEnv || isTestEnv,
          useBuiltIns: true
        }
      ]
    ].filter(Boolean),
    plugins: [
      'babel-plugin-macros',
      '@babel/plugin-syntax-dynamic-import',
      isTestEnv && 'babel-plugin-dynamic-import-node',
      '@babel/plugin-transform-destructuring',
      [
        '@babel/plugin-proposal-class-properties',
        {
          loose: true
        }
      ],
      [
        '@babel/plugin-proposal-object-rest-spread',
        {
          useBuiltIns: true
        }
      ],
      [
        '@babel/plugin-transform-regenerator',
        {
          async: false
        }
      ],
      isProductionEnv && ['babel-plugin-transform-react-remove-prop-types',
        {
          removeImport: true
        }
      ],
      process.env.WEBPACK_SERVE && 'react-refresh/babel'
    ].filter(Boolean)
  };

  resultConfig.presets = [...resultConfig.presets, ...changesOnDefault.presets];
  resultConfig.plugins = [...resultConfig.plugins, ...changesOnDefault.plugins];

  return resultConfig;
};
