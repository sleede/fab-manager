const path = require('path');

module.exports = {
  test: /\.js$/,
  exclude: /node_modules/,
  use: [
    {
      loader: 'auto-ngtemplate-loader',
      options: {
        pathResolver: (templatePath) => path.join(__dirname, `../../../app/frontend/templates${templatePath}`)
      }
    }
  ]
};
