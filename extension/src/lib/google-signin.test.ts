import { describe, expect, it } from 'vitest';

import { authErrorMessage, googleAuthUrl, googleIdTokenFrom } from './sources/backend';

const b64url = (value: object) =>
  btoa(JSON.stringify(value)).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
const token = (nonce: string) => `${b64url({ alg: 'RS256' })}.${b64url({ nonce })}.sig`;
const redirect = (hash: Record<string, string>) =>
  `https://abc.chromiumapp.org/#${new URLSearchParams(hash).toString()}`;

describe('googleAuthUrl', () => {
  it('asks only for an ID token with openid email profile', () => {
    const url = new URL(
      googleAuthUrl('x.apps.googleusercontent.com', 'https://abc.chromiumapp.org/', 's1', 'n1'),
    );
    expect(url.origin + url.pathname).toBe('https://accounts.google.com/o/oauth2/v2/auth');
    expect(Object.fromEntries(url.searchParams)).toEqual({
      client_id: 'x.apps.googleusercontent.com',
      response_type: 'id_token',
      redirect_uri: 'https://abc.chromiumapp.org/',
      scope: 'openid email profile',
      state: 's1',
      nonce: 'n1',
      prompt: 'select_account',
    });
  });
});

describe('googleIdTokenFrom', () => {
  it('returns the ID token when state and nonce match', () => {
    const idToken = token('n1');
    expect(googleIdTokenFrom(redirect({ state: 's1', id_token: idToken }), 's1', 'n1')).toBe(
      idToken,
    );
  });

  it.each([
    ['wrong state', redirect({ state: 'other', id_token: token('n1') })],
    ['wrong nonce', redirect({ state: 's1', id_token: token('other') })],
    ['missing token', redirect({ state: 's1' })],
    ['malformed token', redirect({ state: 's1', id_token: 'not-a-jwt' })],
    ['no redirect', undefined],
    ['broken URL', 'not a url'],
  ])('rejects %s', (_name, url) =>
    expect(() => googleIdTokenFrom(url, 's1', 'n1')).toThrow('không hợp lệ'),
  );

  it('reports a cancelled consent screen', () => {
    expect(() =>
      googleIdTokenFrom(redirect({ error: 'access_denied', state: 's1' }), 's1', 'n1'),
    ).toThrow('Đã huỷ đăng nhập Google.');
  });
});

describe('authErrorMessage for Google', () => {
  it('maps signInWithIdp errors to Vietnamese', () => {
    expect(authErrorMessage('INVALID_IDP_RESPONSE : bad aud')).toContain('Google');
    expect(authErrorMessage('OPERATION_NOT_ALLOWED')).toBe('Attendo chưa bật đăng nhập Google.');
  });
});
