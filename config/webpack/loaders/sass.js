module.exports = {
  test: /\.(scss|sass)$/i,
  exclude: /node_modules/,
  use: [
    {
      loader: require('mini-css-extract-plugin').loader
    },
    {
      loader: 'css-loader',
      options: {
        sourceMap: true,
        importLoaders: 2
      }
    },
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
