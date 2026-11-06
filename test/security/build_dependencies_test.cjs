// Build contracts run against the repository's supported Node and locked toolchain.
// Run with yarn test:build-dependencies; generated fixtures stay in the OS temp directory.
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const babel = require('@babel/core');
const postcss = require('postcss');
const webpack = require('webpack');
const TerserPlugin = require('terser-webpack-plugin');

test('the project Babel configuration preserves TSX and runtime helper behavior', () => {
  const result = babel.transformSync('export const render = (name: string) => <span>{name}</span>;', {
    filename: path.resolve('app/frontend/dependency-contract.tsx'),
    envName: 'test'
  });
  const module = { exports: {} };
  vm.runInNewContext(result.code, { require, module, exports: module.exports }, { timeout: 2000 });
  const element = module.exports.render('Local');
  assert.equal(element.type, 'span');
  assert.equal(element.props.children, 'Local');

  const wrapRegExp = require('@babel/runtime/helpers/wrapRegExp');
  const expression = wrapRegExp(/(\w+)/, { word: 1 });
  assert.equal('local'.replace(expression, '[$<word>]'), '[local]');
  const incomplete = '$<'.repeat(256);
  assert.equal('local'.replace(expression, incomplete), incomplete);
});

test('the production Babel configuration preserves dynamic imports for Webpack', () => {
  const result = babel.transformSync('export const load = () => import("./local.js");', {
    filename: path.resolve('app/frontend/dependency-contract.js'),
    envName: 'production',
    caller: { name: 'babel-loader', supportsStaticESM: true, supportsDynamicImport: true, supportsTopLevelAwait: true }
  });
  assert.match(result.code, /import\(["']\.\/local\.js["']\)/);
});

test('PostCSS 8 preserves CSS and source maps while the legacy loader keeps its parser', async () => {
  const result = await postcss([]).process('.local { display: flex; color: red }', {
    from: 'local.css', to: 'compiled.css', map: { inline: false }
  });
  assert.match(result.css, /display: flex/);
  assert.ok(result.map.toJSON().sources.includes('local.css'));

  const loaderRequire = createRequire(require.resolve('resolve-url-loader/package.json'));
  const legacyParser = loaderRequire('postcss');
  assert.equal(legacyParser.parse('.local { color: red }').first.first.value, 'red');
});

test('PostCSS does not import an unrelated source map outside the stylesheet directory', async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'fab-manager-postcss-'));
  try {
    const mapFile = path.join(directory, 'unrelated.map');
    fs.writeFileSync(mapFile, JSON.stringify({
      version: 3,
      file: 'unrelated.css',
      sources: ['unrelated.css'],
      names: [],
      mappings: 'AAAA',
      sourcesContent: ['LOCAL_SOURCE_MAP_MARKER']
    }));
    const sourceDirectory = path.join(directory, 'source');
    fs.mkdirSync(sourceDirectory);
    const result = await postcss([]).process('.local { color: red }\n/*# sourceMappingURL=../unrelated.map */', {
      from: path.join(sourceDirectory, 'local.css'), map: { inline: false }
    });
    assert.equal(result.root.source.input.map, undefined);
    assert.equal(JSON.stringify(result.map.toJSON()).includes('LOCAL_SOURCE_MAP_MARKER'), false);
  } finally {
    fs.rmSync(directory, { recursive: true });
  }
});

test('Webpack and Terser preserve dynamic imports in a fresh minified build', async () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'fab-manager-webpack-'));
  try {
    fs.writeFileSync(path.join(directory, 'entry.js'),
      'require("regenerator-runtime/runtime"); const underscore = require("underscore/underscore.js"); ' +
      'module.exports = async () => underscore.first([(await import("./local.js")).value]);');
    fs.writeFileSync(path.join(directory, 'local.js'), 'export const value = "local chunk";');
    const output = path.join(directory, 'output');
    const compiler = webpack({
      context: directory,
      mode: 'production',
      target: 'node',
      entry: './entry.js',
      resolve: { modules: [path.resolve('node_modules'), 'node_modules'] },
      output: { path: output, filename: 'main.cjs', chunkFilename: '[id].cjs', library: { type: 'commonjs2' } },
      devtool: 'source-map',
      cache: false,
      optimization: { minimize: true, minimizer: [new TerserPlugin({ parallel: false })] }
    });
    let stats;
    try {
      stats = await new Promise((resolve, reject) => {
        compiler.run((error, result) => error ? reject(error) : resolve(result));
      });
    } finally {
      await new Promise((resolve, reject) => compiler.close(error => error ? reject(error) : resolve()));
    }
    assert.equal(stats.hasErrors(), false, stats.toString({ all: false, errors: true }));
    const assets = stats.toJson({ all: false, assets: true }).assets;
    assert.ok(assets.filter(asset => asset.name.endsWith('.cjs')).length >= 2);
    const load = require(path.join(output, 'main.cjs'));
    assert.equal(await load(), 'local chunk');
    assert.ok(fs.existsSync(path.join(output, 'main.cjs.map')));
  } finally {
    fs.rmSync(directory, { recursive: true });
  }
});
