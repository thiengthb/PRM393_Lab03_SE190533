// Sinh design/tokens/hereby.css từ packages/core/lib/theme/tokens.dart (nguồn duy nhất).
// Extension (và trang nào ngoài Flutter) đọc file CSS này để cùng màu, chữ, bo góc với app.
// Chạy: node tool/tokens/gen_css.mjs   (test mobile/test/tokens_css_test.dart báo lỗi nếu quên chạy)
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const src = readFileSync(join(root, 'packages/core/lib/theme/tokens.dart'), 'utf8');

const kebab = (s) => s.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
const hex = (argb) => {
  const a = parseInt(argb.slice(0, 2), 16);
  const rgb = argb.slice(2).toLowerCase();
  return a === 255 ? `#${rgb}` : `#${rgb}${argb.slice(0, 2).toLowerCase()}`;
};
const block = (name, end = '\n}') => {
  const start = src.indexOf(name);
  if (start < 0) throw new Error(`Không thấy ${name} trong tokens.dart`);
  return src.slice(start, src.indexOf(end, start));
};

const lines = [];
const add = (k, v) => lines.push(`  --${k}: ${v};`);

for (const [, k, v] of block('abstract final class AppColors').matchAll(/static const (\w+) = Color\(0x([0-9A-Fa-f]{8})\)/g)) {
  add(`color-${kebab(k)}`, hex(v));
}
const bien = block('static const bienSau = AppPalette(', '\n  );');
for (const [, k, v] of bien.matchAll(/(\w+): Color\(0x([0-9A-Fa-f]{8})\)/g)) add(`color-${kebab(k)}`, hex(v));
for (const [, k, v] of block('abstract final class AppSpace').matchAll(/static const double (\w+) = (?:s)?(\d+)/g)) {
  add(`space-${kebab(k)}`, `${v}px`);
}
for (const [, k, v] of block('abstract final class AppRadius').matchAll(/static const double (\w+) = (\d+)/g)) {
  add(`radius-${kebab(k)}`, `${v}px`);
}
for (const [, k, v] of block('abstract final class AppLayout').matchAll(/static const double (\w+) = ([\d.]+)/g)) {
  if (k !== 'wideTextScale') add(`layout-${kebab(k)}`, `${v}px`);
}
add('font-sans', `'Nunito', system-ui, -apple-system, 'Segoe UI', sans-serif`);

const css = `/* Sinh tự động bởi tool/tokens/gen_css.mjs từ packages/core/lib/theme/tokens.dart. Không sửa tay. */
/* Bảng màu mặc định Biển sâu. Font Nunito: packages/core/fonts (OFL). */
:root {
${lines.join('\n')}
}
`;
writeFileSync(join(root, 'design/tokens/hereby.css'), css);
console.log(`design/tokens/hereby.css: ${lines.length} biến`);
