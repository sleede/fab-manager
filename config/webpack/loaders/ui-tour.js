module.exports = {
  test: /angular-ui-tour\/.*\.js$/i,
  use: [
    {
      loader: 'imports-loader',
      options: {
        imports: [
          'default hone Hone',
          'default tether Tether'
        ]
      }
    }
  ]
};
