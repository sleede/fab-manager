const path = require('path');

module.exports = {
  test: /\.html$/i,
  exclude: /node_modules/,
  // type: 'asset/inline',
  // generator: {
  //   dataUrl: {
  //     encoding: false,
  //     mimetype: 'application/javascript'
  //   }
  // },
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
