// Zip dist/ into release/fap-attendance-extension-<version>.zip (Chrome Web Store / Edge Add-ons
// upload format, also usable for "Load unpacked" after extraction) and print its SHA-256.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { zipSync } from 'fflate';

const root = path.resolve(import.meta.dirname, '..');
const dist = path.join(root, 'dist');
const { version } = JSON.parse(fs.readFileSync(path.join(dist, 'manifest.json'), 'utf8'));

const entries = {};
for (const entry of fs.readdirSync(dist, { recursive: true, withFileTypes: true })) {
  if (!entry.isFile()) continue;
  const full = path.join(entry.parentPath, entry.name);
  entries[path.relative(dist, full).split(path.sep).join('/')] = fs.readFileSync(full);
}

const out = path.join(root, 'release', `fap-attendance-extension-${version}.zip`);
fs.mkdirSync(path.dirname(out), { recursive: true });
const zip = zipSync(entries, { level: 9, mtime: new Date('2026-01-01T00:00:00Z') });
fs.writeFileSync(out, zip);
const sha = crypto.createHash('sha256').update(zip).digest('hex');
console.log(`${path.relative(root, out)}  ${Object.keys(entries).length} files  sha256 ${sha}`);
