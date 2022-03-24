const isDevelopment = process.env.NODE_ENV !== 'production';

module.exports = {
  test: /\.[jt]sx?$/,
  exclude: /node_modules/,
  use: [
    {
      loader: 'babel-loader',
      options: {
        plugins: [isDevelopment && require.resolve('react-refresh/babel')].filter(Boolean)
      }
    }
  ]
};
