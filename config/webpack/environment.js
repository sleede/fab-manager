const { environment } = require('@rails/webpacker');
const htmlErb = require('./loaders/html_erb');
const jsErb = require('./loaders/js_erb');
const html = require('./loaders/html');
const webpack = require('webpack');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery'
}));

environment.loaders.prepend('js.erb', jsErb);
environment.loaders.prepend('html.erb', htmlErb);
environment.loaders.append('html', html);

environment.splitChunks();

module.exports = environment;
