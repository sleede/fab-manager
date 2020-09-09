const { environment } = require('@rails/webpacker');
const erb = require('./loaders/erb');
const html = require('./loaders/html');
const webpack = require('webpack');

environment.plugins.prepend('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery'
}));

environment.loaders.append('html', html);
environment.loaders.prepend('erb', erb);
environment.splitChunks();

module.exports = environment;
