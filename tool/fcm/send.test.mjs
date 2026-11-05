import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildMessage, staleTokens } from './send.mjs';

test('tin có notification và data.route để app mở đúng màn', () => {
  const m = buildMessage(['a', 'b'], { title: 'T', body: 'B', route: '/requests' });
  assert.deepEqual(m.tokens, ['a', 'b']);
  assert.deepEqual(m.notification, { title: 'T', body: 'B' });
  assert.deepEqual(m.data, { route: '/requests' });
  assert.equal(m.android.priority, 'high');
});

test('chỉ xoá token FCM báo không còn đăng ký', () => {
  const r = [
    { success: true },
    { success: false, error: { code: 'messaging/registration-token-not-registered' } },
    { success: false, error: { code: 'messaging/internal-error' } },
  ];
  assert.deepEqual(staleTokens(['a', 'b', 'c'], r), ['b']);
});
