import { describe, expect, it } from 'vitest';

import { createManifest } from '../../manifest.config';
import { herebyApiOrigins, parseConfig } from './env-config';
import { toClosedSlots, toRows, vnDate } from './sources/backend';
import { parseSheetUrl } from './sources/google-sheets';

describe('parseConfig', () => {
  it('normalizes origins and disables optional features when blank', () => {
    const config = parseConfig({
      VITE_HEREBY_API_KEY: '',
      VITE_FIXTURE_ORIGINS: 'https://fixture.example.test/path, http://localhost:4173',
    });
    expect(config.hereby).toBeNull();
    expect(config.fixtureOrigins).toEqual([
      'https://fixture.example.test',
      'http://localhost:4173',
    ]);
    expect(config.googleClientId).toBeNull();
  });

  it.each([
    ['live FAP', { VITE_FIXTURE_ORIGINS: 'https://fap.fpt.edu.vn' }, 'disabled'],
    ['plain http', { VITE_FIXTURE_ORIGINS: 'http://fixture.example.test' }, 'https'],
    ['bad client id', { VITE_GOOGLE_CLIENT_ID: 'abc' }, 'apps.googleusercontent.com'],
    ['bad project id', { VITE_HEREBY_PROJECT_ID: 'Bad Project' }, 'Firebase project ID'],
  ])('rejects %s', (_name, env, message) => expect(() => parseConfig(env)).toThrow(message));
});

describe('Attendo mặc định', () => {
  it('bật nguồn Attendo với project hereby-se190533 và cho FAP giả lập trên Hosting', () => {
    const env = { VITE_HEREBY_API_KEY: 'public-web-key' };
    const config = parseConfig(env);
    expect(config.hereby?.projectId).toBe('hereby-se190533');
    expect(config.fixtureOrigins).toContain('https://hereby-se190533.web.app');
    const manifest = createManifest(env) as chrome.runtime.ManifestV3;
    expect(manifest.host_permissions).toEqual(
      expect.arrayContaining([
        'https://identitytoolkit.googleapis.com/*',
        'https://securetoken.googleapis.com/*',
        'https://firestore.googleapis.com/*',
      ]),
    );
  });
});

describe('Firebase Emulator (bản build test luồng)', () => {
  it('đổi Auth và Firestore sang emulator trên máy, không xin quyền googleapis', () => {
    const env = { VITE_HEREBY_API_KEY: 'demo', VITE_HEREBY_EMULATOR_HOST: '127.0.0.1' };
    const config = parseConfig(env);
    expect(config.hereby?.emulatorHost).toBe('127.0.0.1');
    expect(herebyApiOrigins(config.hereby!)).toEqual({
      auth: 'http://127.0.0.1:9099/identitytoolkit.googleapis.com',
      token: 'http://127.0.0.1:9099/securetoken.googleapis.com',
      firestore: 'http://127.0.0.1:8080',
    });
    const manifest = createManifest(env) as chrome.runtime.ManifestV3;
    expect(manifest.host_permissions).toEqual(
      expect.arrayContaining(['http://127.0.0.1:9099/*', 'http://127.0.0.1:8080/*']),
    );
    expect(manifest.host_permissions?.some((p) => p.includes('googleapis'))).toBe(false);
  });

  it('chỉ nhận localhost hoặc 127.0.0.1', () => {
    expect(() =>
      parseConfig({ VITE_HEREBY_API_KEY: 'k', VITE_HEREBY_EMULATOR_HOST: 'example.com' }),
    ).toThrow(/localhost or 127.0.0.1/);
  });

  it('mặc định không bật emulator', () => {
    expect(parseConfig({ VITE_HEREBY_API_KEY: 'k' }).hereby?.emulatorHost).toBeNull();
  });
});

describe('manifest', () => {
  it('requests identity and Sheets host only when Google is configured', () => {
    const plain = createManifest({}) as chrome.runtime.ManifestV3;
    expect(plain.permissions).not.toContain('identity');
    const google = createManifest({
      VITE_GOOGLE_CLIENT_ID: 'x.apps.googleusercontent.com',
    }) as chrome.runtime.ManifestV3;
    expect(google.permissions).toContain('identity');
    expect(google.host_permissions).toContain('https://sheets.googleapis.com/*');
  });

  it('never asks for cookies, webRequest or live FAP, and declares no always-on content script', () => {
    const manifest = createManifest({
      VITE_GOOGLE_CLIENT_ID: 'x.apps.googleusercontent.com',
    }) as chrome.runtime.ManifestV3;
    const text = JSON.stringify(manifest);
    for (const forbidden of [
      'cookies',
      'webRequest',
      'fpt.edu.vn',
      '<all_urls>',
      'externally_connectable',
    ]) {
      expect(text).not.toContain(forbidden);
    }
    expect(manifest.content_scripts).toBeUndefined();
  });
});

describe('small parsers', () => {
  it('đổi giờ Firestore sang ngày Việt Nam', () => {
    expect(vnDate('2026-11-03T00:30:00Z')).toBe('2026-11-03');
    expect(vnDate('2026-11-03T18:00:00Z')).toBe('2026-11-04');
    expect(vnDate('')).toBe('');
  });

  it('chỉ lấy slot đã chốt, mới nhất trước', () => {
    const doc = (id: string, start: string, slotNo: string, closed: boolean) => ({
      document: {
        name: `projects/p/databases/(default)/documents/slots/${id}`,
        fields: {
          subject: { stringValue: 'PRM393' },
          classCode: { stringValue: 'SE1801' },
          start: { timestampValue: start },
          slotNo: { integerValue: slotNo },
          room: { stringValue: 'P.305' },
          closed: { booleanValue: closed },
        },
      },
    });
    const slots = toClosedSlots([
      doc('a', '2026-11-03T00:00:00Z', '1', true),
      doc('b', '2026-11-05T00:00:00Z', '1', true),
      doc('c', '2026-11-06T00:00:00Z', '1', false),
      { readTime: 'x' },
    ]);
    expect(slots.map((s) => s.id)).toEqual(['b', 'a']);
    expect(slots[0]).toEqual({
      id: 'b',
      course: 'PRM393',
      group: 'SE1801',
      date: '2026-11-05',
      slot: '1',
      room: 'P.305',
    });
  });

  it('đổi bản ghi điểm danh đã chốt thành ATTEND/ABSENT', () => {
    const rec = (code: string, present: boolean, final = true) => ({
      name: `x/attendance/${code}`,
      fields: {
        studentCode: { stringValue: code },
        present: { booleanValue: present },
        final: { booleanValue: final },
      },
    });
    expect(
      toRows({
        documents: [rec('SE190102', false), rec('SE190101', true), rec('SE190103', true, false)],
      }),
    ).toEqual([
      { studentCode: 'SE190101', status: 'ATTEND' },
      { studentCode: 'SE190102', status: 'ABSENT' },
    ]);
    expect(toRows({})).toEqual([]);
  });

  it('parses sheet links with and without gid', () => {
    const id = '1AbCdEfGhIjKlMnOpQrStUvWxYz0123456789';
    expect(parseSheetUrl(`https://docs.google.com/spreadsheets/d/${id}/edit#gid=42`)).toEqual({
      spreadsheetId: id,
      gid: 42,
    });
    expect(parseSheetUrl(id)).toEqual({ spreadsheetId: id, gid: null });
    expect(() => parseSheetUrl('https://evil.example.test/spreadsheets/d/' + id)).toThrow();
  });
});
