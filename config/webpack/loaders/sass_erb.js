const getStyleRule = require('@rails/webpacker/package/utils/get_style_rule');

module.exports = getStyleRule(/\.(scss|sass)\.erb$/, false, [
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
  },
  {
    loader: 'rails-erb-loader'
  }
]);
