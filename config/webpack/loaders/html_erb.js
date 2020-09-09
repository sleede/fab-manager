module.exports = {
  test: /\.html\.erb$/,
  loader: [
    'rails-erb-loader',
    'html-loader'
  ]
};
