module.exports = {
  test: require.resolve('../../../app/frontend/src/javascript/app.js'),
  loader: 'expose-loader',
  options: {
    exposes: 'app'
  }
};
