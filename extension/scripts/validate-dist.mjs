// Release gate on the BUILT extension (what actually ships), complementing the source tests.
import fs from 'node:fs';
import path from 'node:path';

const dist = path.resolve(import.meta.dirname, '..', 'dist');
const manifest = JSON.parse(fs.readFileSync(path.join(dist, 'manifest.json'), 'utf8'));
const problems = [];
const check = (ok, message) => ok || problems.push(message);

check(manifest.manifest_version === 3, 'manifest_version must be 3');
check(!manifest.content_scripts, 'no always-on content_scripts; the adapter is injected on demand');
check(!manifest.web_accessible_resources, 'web_accessible_resources must be stripped');
check(!manifest.externally_connectable, 'externally_connectable is not allowed');
for (const permission of ['cookies', 'webRequest', 'webRequestBlocking', 'tabs', 'history']) {
  check(!manifest.permissions?.includes(permission), `permission "${permission}" is not allowed`);
}
for (const host of manifest.host_permissions ?? []) {
  check(
    !/fpt\.edu\.vn|<all_urls>|^\*:|^https?:\/\/\*\//.test(host),
    `host "${host}" is too broad or live FAP`,
  );
}
check(
  fs.existsSync(path.join(dist, manifest.side_panel?.default_path ?? '')),
  'side panel page missing',
);
check(fs.existsSync(path.join(dist, 'src/content/index.js')), 'IIFE page adapter missing');

const adapter = fs.readFileSync(path.join(dist, 'src/content/index.js'), 'utf8');
for (const forbidden of ['.click()', 'requestSubmit', '__doPostBack', '.submit()']) {
  check(!adapter.includes(forbidden), `built adapter contains "${forbidden}"`);
}

if (problems.length) {
  console.error(`dist validation failed:\n- ${problems.join('\n- ')}`);
  process.exit(1);
}
console.log(`dist OK: ${manifest.name} ${manifest.version}`);
