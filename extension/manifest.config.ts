import { defineManifest } from '@crxjs/vite-plugin';

import pkg from './package.json' with { type: 'json' };
import { originPattern, parseConfig } from './src/lib/env-config';

export const SHEETS_API_ORIGIN = 'https://sheets.googleapis.com';

/** Firebase Auth (đăng nhập, làm mới token) và Firestore REST cho nguồn Attendo. */
export const HEREBY_API_ORIGINS = [
  'https://identitytoolkit.googleapis.com',
  'https://securetoken.googleapis.com',
  'https://firestore.googleapis.com',
] as const;

/**
 * Least privilege: every permission below is tied to a configured feature. No live FAP origin, no
 * cookies, no webRequest, no externally_connectable, no remote code (docs/decisions.md D-001).
 */
export function createManifest(env: Record<string, string | undefined>) {
  const config = parseConfig(env);
  const hostPermissions = [...config.fixtureOrigins.map(originPattern), 'file:///*'];
  if (config.hereby) hostPermissions.push(...HEREBY_API_ORIGINS.map(originPattern));
  if (config.googleClientId) hostPermissions.push(originPattern(SHEETS_API_ORIGIN));

  const permissions: chrome.runtime.ManifestPermission[] = [
    'sidePanel',
    'activeTab',
    'scripting',
    'storage',
  ];
  if (config.googleClientId) permissions.push('identity');

  return defineManifest({
    manifest_version: 3,
    name: 'Attendo cho FAP',
    short_name: 'Attendo FAP',
    version: pkg.version,
    description:
      'Preview, fill and verify attendance on recognized FAP-style pages from an approved batch, a CSV/XLSX file or a Google Sheet. Never saves to live FAP.',
    minimum_chrome_version: '116',
    ...(config.extensionPublicKey ? { key: config.extensionPublicKey } : {}),
    icons: {
      16: 'icons/icon-16.png',
      32: 'icons/icon-32.png',
      48: 'icons/icon-48.png',
      128: 'icons/icon-128.png',
    },
    action: {
      default_title: 'Attendo cho FAP',
      default_icon: { 16: 'icons/icon-16.png', 32: 'icons/icon-32.png' },
    },
    side_panel: { default_path: 'src/sidepanel/index.html' },
    background: { service_worker: 'src/background/service-worker.ts', type: 'module' },
    permissions,
    host_permissions: hostPermissions,
    commands: {
      _execute_action: {
        suggested_key: { default: 'Alt+Shift+F' },
        description: 'Mở bảng điểm danh FAP',
      },
    },
  });
}
