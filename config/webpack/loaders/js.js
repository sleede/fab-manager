module.exports = {
  test: /\.js$/,
  exclude: /node_modules/,
  use: [
    {
      loader: 'auto-ngtemplate-loader',
      options: {
        pathResolver: (p) => p.replace(/src\/javascript\/.*$/, 'templates')
      }
    }
  ]
};
