const path = require('path');

module.exports = {
  test: /\.js\.erb$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: [
    {
      loader: 'auto-ngtemplate-loader',
      options: {
        pathResolver: (templatePath) => path.join(__dirname, `../../../app/frontend/templates${templatePath}`)
      }
    },
    {
      loader: 'rails-erb-loader',
      options: {
        runner: (/^win/.test(process.platform) ? 'ruby ' : '') + 'bin/rails runner'
      }
    }
  ]
};
