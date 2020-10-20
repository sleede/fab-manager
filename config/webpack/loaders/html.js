const path = require('path');

module.exports = {
  test: /\.html$/i,
  exclude: /node_modules/,
  use: [
    {
      loader: 'ngtemplate-loader',
      options: {
        relativeTo: path.join(__dirname, '../../../app/frontend/templates'),
        requireAngular: true
      }
    },
    {
      loader: 'html-loader'
    }
  ]
};
