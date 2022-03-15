const path = require('path');

module.exports = {
  test: /angular-ui-tour\/.*\.html$/i,
  use: [
    {
      loader: 'ngtemplate-loader',
      options: {
        relativeTo: path.join(__dirname, '../../../node_modules/angular-ui-tour/app/templates'),
        requireAngular: true
      }
    },
    {
      loader: 'html-loader'
    }
  ]
};
