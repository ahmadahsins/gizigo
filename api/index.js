const fs = require('fs');
const path = require('path');

const bundledDist = path.join(__dirname, 'dist');
const localDist = path.join(process.cwd(), 'backend', 'dist');
const distRoot = fs.existsSync(path.join(bundledDist, 'src', 'serverless.js'))
  ? bundledDist
  : localDist;

const handler = require(path.join(distRoot, 'src', 'serverless.js')).default;

module.exports = handler;
