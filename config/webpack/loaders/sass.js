module.exports = {
  test: /\.(scss|sass)$/i,
  use: [
    {
      loader: 'css-loader',
      options: {
        sourceMap: true
      }
    },
    {
      loader: 'resolve-url-loader'
    },
    {
      loader: 'sass-loader'
    }
  ]
};
