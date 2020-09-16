module.exports = {
  test: /\.js(\?.erb)?$/,
  use: [
    {
      loader: 'imports-loader',
      options: {
        imports: [
          'default Application Application'
        ]
      }
    }
  ]
};
