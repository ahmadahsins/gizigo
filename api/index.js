const path = require('path');
const Module = require('module');

const backendRoot = path.join(process.cwd(), 'backend');
const backendNodeModules = path.join(backendRoot, 'node_modules');

Module._initPaths([backendNodeModules]);

const handler = require(path.join(
  backendRoot,
  'dist',
  'src',
  'serverless.js',
)).default;

module.exports = handler;
