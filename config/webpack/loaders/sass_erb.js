module.exports = {
  test: /\.(scss|sass)\.erb$/,
  enforce: 'pre',
  exclude: /node_modules/,
  loader: [
    'sass-loader',
    'rails-erb-loader'
  ]
};
