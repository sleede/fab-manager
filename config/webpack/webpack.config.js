const { webpackConfig, merge } = require('shakapacker');
const webpack = require('webpack');
const path = require('path');

const htmlErb = require('./loaders/html_erb');
const js = require('./loaders/js');
const jsErb = require('./loaders/js_erb');
const sass = require('./loaders/sass');
const sassErb = require('./loaders/sass_erb');
const html = require('./loaders/html');
const uiTour = require('./loaders/ui-tour');

// See the shakacode/shakapacker README and docs directory for advice on customizing your webpackConfig.
const customConfig = {
  plugins: [
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
      _: 'lodash',
      Hone: 'hone',
      Tether: 'tether',
      Holder: 'holderjs',
      'window.CodeMirror': 'codemirror',
      MediumEditor: 'medium-editor',
      Humanize: path.resolve(path.join(__dirname, '../../app/frontend/src/javascript/lib/humanize.js')),
      moment: 'moment',
      Application: [path.resolve(path.join(__dirname, '../../app/frontend/src/javascript/app.js')), 'Application']
    })
  ],
  module: {
    rules: [
      jsErb,
      htmlErb,
      sassErb,
      js,
      html,
      sass,
      uiTour
    ]
  },
  resolve: {
    extensions: ['.jpg', '.jpeg', '.png', '.gif', '.tiff', '.ico',
      '.svg', '.eot', '.otf', '.ttf', '.woff', '.woff2',
      '.tsx', '.ts', '.erb', '.html', '.mjs', '.js', '.jsx',
      '.sass', '.scss', '.css', '.module.sass', '.module.scss', '.module.css'],
    fallback: {
      assert: false
    }
  }
};

module.exports = merge(webpackConfig, customConfig);
