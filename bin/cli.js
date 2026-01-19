#!/usr/bin/env node

/**
 * Universal CI - CLI Entry Point
 * 
 * This Node.js wrapper allows running Universal CI via npx or as an installed binary.
 * It acts as a thin shell that delegates to run-ci.sh
 * 
 * Usage:
 *   npx @orchestrate-solutions/universal-ci init
 *   npx @orchestrate-solutions/universal-ci --stage release
 *   npm run ci
 */

const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Determine the script path (handle both local dev and npm install scenarios)
const scriptDir = path.dirname(__dirname);
const runCiPath = path.join(scriptDir, 'run-ci.sh');

// Verify run-ci.sh exists
if (!fs.existsSync(runCiPath)) {
  console.error('❌ Error: run-ci.sh not found at', runCiPath);
  process.exit(1);
}

// Make sure it's executable
fs.chmodSync(runCiPath, 0o755);

// Pass all arguments to run-ci.sh
const args = process.argv.slice(2);

// Spawn the shell script with all arguments
const child = spawn('sh', [runCiPath, ...args], {
  stdio: 'inherit',
  shell: true
});

// Exit with the same code as the shell script
child.on('close', (code) => {
  process.exit(code);
});

// Handle errors
child.on('error', (err) => {
  console.error('❌ Error executing run-ci.sh:', err.message);
  process.exit(1);
});
