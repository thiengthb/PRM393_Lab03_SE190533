import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

/**
 * Repository gates, in the spirit of sakubun's lib/no-emoji.test.ts and type-scale.test.ts: rules
 * that were easy to state and easy to break are checked here instead of only in docs.
 */
const root = path.resolve(import.meta.dirname, '..');

function files(dir: string, pattern: RegExp): string[] {
  return fs
    .readdirSync(path.join(root, dir), { withFileTypes: true, recursive: true })
    .filter((entry) => entry.isFile() && pattern.test(entry.name))
    .map((entry) => path.join(entry.parentPath, entry.name));
}

const sources = files('src', /\.(ts|tsx|css|html)$/);

describe('gates', () => {
  it('no emoji anywhere in source (D-005)', () => {
    const emoji = /\p{Extended_Pictographic}/u;
    const offenders = sources.flatMap((file) =>
      fs
        .readFileSync(file, 'utf8')
        .split('\n')
        .flatMap((line, i) => (emoji.test(line) ? [`${path.relative(root, file)}:${i + 1}`] : [])),
    );
    expect(offenders).toEqual([]);
  });

  it('the page adapter never clicks, submits or posts back (D-002)', () => {
    const adapter = fs.readFileSync(path.join(root, 'src/content/fap-v2-adapter.ts'), 'utf8');
    const code = adapter.replace(/\/\*[\s\S]*?\*\/|\/\/.*$/gm, '');
    for (const forbidden of [
      '.click(',
      '.submit(',
      'requestSubmit',
      '__doPostBack',
      'btnSave',
      'fetch(',
      'XMLHttpRequest',
      'dispatchEvent(new MouseEvent',
      "new Event('submit'",
      "new Event('click'",
    ]) {
      expect(code, forbidden).not.toContain(forbidden);
    }
  });

  it('no arbitrary font sizes outside the shadcn primitives (type scale)', () => {
    const offenders = sources
      .filter((file) => !file.includes(`${path.sep}ui${path.sep}`))
      .filter((file) => /text-\[\d/.test(fs.readFileSync(file, 'utf8')));
    expect(offenders.map((file) => path.relative(root, file))).toEqual([]);
  });

  it('no secrets or student data committed', () => {
    const suspicious = /(AIza[0-9A-Za-z_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY|@fpt\.edu\.vn)/;
    const tracked = [...sources, path.join(root, '.env'), path.join(root, '.env.example')];
    // Web API key của Firebase là định danh công khai (quyền do Security Rules quyết định), nên
    // dòng VITE_HEREBY_API_KEY trong .env được bỏ qua; mọi chỗ khác vẫn không được có khoá AIza.
    const read = (file: string) =>
      fs
        .readFileSync(file, 'utf8')
        .split('\n')
        .filter((line) => !line.startsWith('VITE_HEREBY_API_KEY='))
        .join('\n');
    expect(tracked.filter((file) => suspicious.test(read(file)))).toEqual([]);
  });
});
