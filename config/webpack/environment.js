const { environment } = require('@rails/webpacker');
const htmlErb = require('./loaders/html_erb');
const jsErb = require('./loaders/js_erb');
const sassErb = require('./loaders/sass_erb');
const html = require('./loaders/html');
const webpack = require('webpack');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  'window.jQuery': 'jquery',
  Hone: 'hone',
  Tether: 'tether'
}));

environment.loaders.prepend('js.erb', jsErb);
environment.loaders.prepend('html.erb', htmlErb);
environment.loaders.prepend('sass-erb', sassErb);
environment.loaders.append('html', html);

environment.splitChunks();

module.exports = environment;
