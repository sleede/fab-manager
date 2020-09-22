module.exports = {
  test: /\.js\.erb$/,
  enforce: 'pre',
  exclude: /node_modules/,
  use: [
    {
      loader: 'auto-ngtemplate-loader'
    },
    {
      loader: 'rails-erb-loader',
      options: {
        runner: (/^win/.test(process.platform) ? 'ruby ' : '') + 'bin/rails runner'
      }
    }
  ]
};
