module.exports = {
  test: /\.html(\.erb)?$/,
  use: [{
    loader: 'html-loader',
    options: {
      minimize: true,
      removeAttributeQuotes: false,
      caseSensitive: true,
      customAttrSurround: [[/#/, /(?:)/], [/\*/, /(?:)/], [/\[?\(?/, /(?:)/]],
      customAttrAssign: [/\)?\]?=/]
    }
  }]
};
