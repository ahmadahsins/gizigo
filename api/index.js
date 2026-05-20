const fs = require('fs');
const path = require('path');
const Module = require('module');

const bundledDist = path.join(__dirname, 'backend-dist');
const localDist = path.join(process.cwd(), 'backend', 'dist');
const distRoot = fs.existsSync(bundledDist) ? bundledDist : localDist;

const backendNodeModules = path.join(process.cwd(), 'backend', 'node_modules');
if (fs.existsSync(backendNodeModules)) {
  Module._initPaths([backendNodeModules]);
}

const handler = require(path.join(distRoot, 'src', 'serverless.js')).default;

module.exports = handler;
