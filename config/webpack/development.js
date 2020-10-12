process.env.NODE_ENV = process.env.NODE_ENV || 'development';

const environment = require('./environment');

const html = environment.loaders.get('html');
html.use[0].options.prefix = '../../templates';
environment.loaders.delete('html');
environment.loaders.append('html', html);

const htmlErb = environment.loaders.get('html-erb');
htmlErb.use[0].options.prefix = '../../templates';
environment.loaders.delete('html-erb');
environment.loaders.prepend('html-erb', htmlErb);

module.exports = environment.toWebpackConfig();
