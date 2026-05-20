const fs = require('fs');
const path = require('path');

const bundledDist = path.join(__dirname, 'dist');
const fallbackDist = path.join(__dirname, '..', 'dist');
const distRoot = fs.existsSync(path.join(bundledDist, 'src', 'serverless.js'))
  ? bundledDist
  : fallbackDist;

module.exports = require(path.join(distRoot, 'src', 'serverless.js')).default;
