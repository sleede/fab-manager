process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const environment = require('./environment');

const js = environment.loaders.get('js');
delete js.use[0].options.pathResolver;
environment.loaders.delete('js');
environment.loaders.append('js', js);

const jsErb = environment.loaders.get('js-erb');
delete jsErb.use[0].options.pathResolver;
environment.loaders.delete('js-erb');
environment.loaders.prepend('js-erb', jsErb);

module.exports = environment.toWebpackConfig();
