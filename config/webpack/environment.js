const { environment } = require('@rails/webpacker');

environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery'
}));

environment.splitChunks();

module.exports = environment;
