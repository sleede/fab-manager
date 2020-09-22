const { environment } = require('@rails/webpacker');
const webpack = require('webpack');
const path = require('path');

const htmlErb = require('./loaders/html_erb');
const js = require('./loaders/js');
const jsErb = require('./loaders/js_erb');
const sass = require('./loaders/sass');
const sassErb = require('./loaders/sass_erb');
const html = require('./loaders/html');
const uiTour = require('./loaders/ui-tour');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  'window.jQuery': 'jquery',
  Hone: 'hone',
  Tether: 'tether',
  Holder: 'holderjs',
  'window.CodeMirror': 'codemirror',
  MediumEditor: 'medium-editor',
  Humanize: path.resolve(path.join(__dirname, '../../app/frontend/src/javascript/lib/humanize.js')),
  moment: 'moment',
  Application: [path.resolve(path.join(__dirname, '../../app/frontend/src/javascript/app.js')), 'Application']
}));

environment.loaders.prepend('js-erb', jsErb);
environment.loaders.prepend('html-erb', htmlErb);
environment.loaders.prepend('sass-erb', sassErb);
environment.loaders.prepend('js', js);
environment.loaders.append('html', html);
environment.loaders.append('sass', sass);
environment.loaders.append('uiTour', uiTour);

environment.splitChunks();

module.exports = environment;
