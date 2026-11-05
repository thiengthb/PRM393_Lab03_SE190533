import { z } from 'zod';

import type { SourceBatch } from '../attendance';
import { config } from '../config';
import { parseAttendanceGrid } from '../grid';

/**
 * Read-only Google Sheets source. OAuth runs through chrome.identity.launchWebAuthFlow (works in
 * Chrome and Edge) with the `spreadsheets.readonly` scope only. The short-lived access token is kept
 * in chrome.storage.session; there is no refresh token and nothing is written back to the sheet.
 */

const SCOPE = 'https://www.googleapis.com/auth/spreadsheets.readonly';
const TOKEN_KEY = 'googleToken';
const API = 'https://sheets.googleapis.com/v4/spreadsheets';

export class SheetsError extends Error {
  override name = 'SheetsError';
}

export function isSheetsEnabled(): boolean {
  return config.googleClientId !== null;
}

export type SheetRef = Readonly<{ spreadsheetId: string; gid: number | null }>;

/** Accept a full Google Sheets URL (optionally with #gid=...) or a bare spreadsheet ID. */
export function parseSheetUrl(input: string): SheetRef {
  const value = input.trim();
  if (/^[\w-]{25,}$/.test(value)) return { spreadsheetId: value, gid: null };
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new SheetsError('Link Google Sheet không hợp lệ.');
  }
  const id = url.pathname.match(/\/spreadsheets\/d\/([\w-]{25,})/)?.[1];
  if (url.hostname !== 'docs.google.com' || !id) {
    throw new SheetsError('Link phải có dạng https://docs.google.com/spreadsheets/d/...');
  }
  const gidText = url.hash.match(/gid=(\d+)/)?.[1] ?? url.searchParams.get('gid');
  return { spreadsheetId: id, gid: gidText ? Number(gidText) : null };
}

const storedTokenSchema = z.object({ accessToken: z.string().min(1), expiresAt: z.number() });

async function storedToken(): Promise<string | null> {
  const raw = (await chrome.storage.session.get(TOKEN_KEY))[TOKEN_KEY];
  const parsed = storedTokenSchema.safeParse(raw);
  if (!parsed.success || parsed.data.expiresAt - 60_000 <= Date.now()) return null;
  return parsed.data.accessToken;
}

export async function hasGoogleToken(): Promise<boolean> {
  return (await storedToken()) !== null;
}

export async function forgetGoogleToken(): Promise<void> {
  await chrome.storage.session.remove(TOKEN_KEY);
}

async function authorize(): Promise<string> {
  if (!config.googleClientId) throw new SheetsError('Bản build này chưa cấu hình Google.');
  const state = crypto.randomUUID();
  const url = new URL('https://accounts.google.com/o/oauth2/v2/auth');
  url.search = new URLSearchParams({
    client_id: config.googleClientId,
    response_type: 'token',
    redirect_uri: chrome.identity.getRedirectURL(),
    scope: SCOPE,
    state,
    include_granted_scopes: 'true',
  }).toString();
  let redirect: string | undefined;
  try {
    redirect = await chrome.identity.launchWebAuthFlow({ url: url.toString(), interactive: true });
  } catch {
    throw new SheetsError('Chưa cấp quyền đọc Google Sheets.');
  }
  const params = new URLSearchParams(new URL(redirect ?? 'about:blank').hash.slice(1));
  const token = params.get('access_token');
  if (params.get('state') !== state || !token) {
    throw new SheetsError('Phản hồi đăng nhập Google không hợp lệ.');
  }
  const expiresIn = Number(params.get('expires_in') ?? '0') || 3600;
  await chrome.storage.session.set({
    [TOKEN_KEY]: { accessToken: token, expiresAt: Date.now() + expiresIn * 1000 },
  });
  return token;
}

async function getJson(url: string, token: string): Promise<unknown> {
  const response = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
  if (response.status === 401) {
    await forgetGoogleToken();
    throw new SheetsError('Phiên Google đã hết hạn. Hãy kết nối lại.');
  }
  if (response.status === 403 || response.status === 404) {
    throw new SheetsError('Không mở được Sheet: kiểm tra link và quyền xem của tài khoản Google.');
  }
  if (!response.ok) throw new SheetsError(`Google Sheets trả lỗi ${response.status}.`);
  return response.json();
}

const metadataSchema = z.object({
  properties: z.object({ title: z.string() }),
  sheets: z.array(z.object({ properties: z.object({ sheetId: z.number(), title: z.string() }) })),
});
const valuesSchema = z.object({ values: z.array(z.array(z.unknown())).default([]) });

export async function readAttendanceSheet(input: string): Promise<SourceBatch> {
  const ref = parseSheetUrl(input);
  const token = (await storedToken()) ?? (await authorize());
  const metadata = metadataSchema.parse(
    await getJson(
      `${API}/${ref.spreadsheetId}?fields=properties.title,sheets.properties(sheetId,title)`,
      token,
    ),
  );
  const tab =
    ref.gid === null
      ? metadata.sheets[0]
      : metadata.sheets.find((sheet) => sheet.properties.sheetId === ref.gid);
  if (!tab) throw new SheetsError('Không tìm thấy tab có gid này trong Sheet.');
  const range = encodeURIComponent(`'${tab.properties.title.replaceAll("'", "''")}'`);
  const { values } = valuesSchema.parse(
    await getJson(`${API}/${ref.spreadsheetId}/values/${range}?majorDimension=ROWS`, token),
  );
  const parsed = parseAttendanceGrid(values);
  return {
    kind: 'sheet',
    label: `${metadata.properties.title} / ${tab.properties.title}`,
    context: parsed.context,
    rows: parsed.rows,
  };
}
