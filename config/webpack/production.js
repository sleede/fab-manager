process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const environment = require('./environment');
const config = environment.toWebpackConfig();
delete config.optimization.minimizer;

module.exports = config;
