// eslint-disable-next-line @typescript-eslint/no-var-requires,no-undef
// Resolve webpack from @angular-devkit/build-angular so the plugin comes from
// the same webpack instance that creates the compiler. npm hoists a newer
// webpack (5.112.1) to node_modules/webpack while build-angular pins its own
// 5.105.0 copy; a plugin from one version on the other version's compiler
// throws "Cannot read properties of undefined (reading 'tap')".
const path = require('path');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const webpack = require(require.resolve('webpack', {
  paths: [path.dirname(require.resolve('@angular-devkit/build-angular/package.json'))],
}));

/**
 * Custom angular webpack configuration
 */
module.exports = (config, options) => {
  config.plugins = [
    ...config.plugins,
    new webpack.IgnorePlugin({
      resourceRegExp: /config\/private\/Config/,
    })
  ];

  return config;
}
