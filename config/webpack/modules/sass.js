module.exports = {
  test: /\.(scss|sass)$/i,
  exclude: /node_modules/,
  use: [
    {
      loader: 'resolve-url-loader',
      options: {
        sourceMap: true
      }
    },
    {
      loader: 'sass-loader',
      options: {
        sourceMap: true,
        sassOptions: {
          includePaths: ['app/frontend/src/stylesheets']
        }
      }
    }
  ]
};
