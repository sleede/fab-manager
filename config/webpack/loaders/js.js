module.exports = {
  test: /\.js$/,
  exclude: /node_modules/,
  use: [
    {
      loader: 'auto-ngtemplate-loader'
    }
  ]
};
