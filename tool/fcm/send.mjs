// Gửi thông báo FCM tới mọi máy của một người dùng Attendo. Đây là phần "server" của FCM:
// chạy trên laptop của nhóm phát triển bằng Firebase Admin SDK, không nằm trong app.
//
//   cd tool/fcm && npm ci
//   export GOOGLE_APPLICATION_CREDENTIALS=/đường/dẫn/service-account.json   # KHÔNG commit file này
//   node send.mjs --to quanm@fe.edu.vn --title "Có yêu cầu sửa mới" --body "SE190101 báo sai buổi 03/11" --route /requests
//   node send.mjs --to quanm@fe.edu.vn --dry-run                              # chỉ in token, không gửi
//
// Các bước:
//   1. Tìm uid theo email (Firebase Auth).
//   2. Đọc token ở users/{uid}/fcmTokens (app Android ghi khi đăng nhập, xem mobile/lib/firebase/fcm_token_sync.dart).
//   3. Gọi FCM HTTP v1 qua Admin SDK (sendEachForMulticast). Phần data.route để app mở đúng màn khi chạm.
//   4. Token báo "không còn đăng ký" thì xoá khỏi Firestore (app đã gỡ hoặc cài lại).
// Admin SDK dùng service account nên bỏ qua Security Rules: chỉ máy của nhóm phát triển giữ file này.

import { parseArgs } from 'node:util';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

const ROUTES = ['/overview', '/requests', '/inbox', '/classes', '/schedule', '/account'];

export function buildMessage(tokens, { title, body, route }) {
  return {
    tokens,
    notification: { title, body },
    // data chỉ nhận chuỗi; app đọc data.route trong messaging_service.dart (_open).
    data: route ? { route } : {},
    // Kênh trùng default_notification_channel_id trong mobile/android/app/src/main/AndroidManifest.xml.
    android: { priority: 'high', notification: { channelId: 'attendo' } },
  };
}

/** Token cần xoá: FCM trả lỗi không còn đăng ký hoặc token sai dạng. */
export function staleTokens(tokens, responses) {
  const dead = new Set(['messaging/registration-token-not-registered', 'messaging/invalid-registration-token']);
  return tokens.filter((_, i) => !responses[i].success && dead.has(responses[i].error?.code));
}

async function main() {
  const { values } = parseArgs({
    options: {
      to: { type: 'string' },
      title: { type: 'string', default: 'Attendo test' },
      body: { type: 'string', default: 'Tin thử từ tool/fcm/send.mjs' },
      route: { type: 'string', default: '/requests' },
      project: { type: 'string', default: process.env.FIREBASE_PROJECT ?? 'attendo-app-2611' },
      'dry-run': { type: 'boolean', default: false },
    },
  });
  if (!values.to) throw new Error('Thiếu --to <email người nhận>');
  if (values.route && !ROUTES.includes(values.route)) {
    throw new Error(`--route phải là một trong: ${ROUTES.join(', ')}`);
  }
  initializeApp({ credential: applicationDefault(), projectId: values.project });

  const user = await getAuth().getUserByEmail(values.to);
  const snap = await getFirestore().collection('users').doc(user.uid).collection('fcmTokens').get();
  const tokens = snap.docs.map((d) => d.id);
  console.log(`${values.to} (${user.uid}): ${tokens.length} máy`);
  if (tokens.length === 0) {
    console.log('Chưa có token. Đăng nhập app Android bằng tài khoản này một lần rồi chạy lại.');
    return;
  }
  if (values['dry-run']) {
    tokens.forEach((t) => console.log(`  ${t.slice(0, 24)}…`));
    return;
  }
  const res = await getMessaging().sendEachForMulticast(buildMessage(tokens, values));
  console.log(`Đã gửi: ${res.successCount} thành công, ${res.failureCount} lỗi`);
  res.responses.forEach((r, i) => !r.success && console.log(`  lỗi ${tokens[i].slice(0, 12)}…: ${r.error?.code}`));
  const stale = staleTokens(tokens, res.responses);
  await Promise.all(stale.map((t) => snap.docs.find((d) => d.id === t).ref.delete()));
  if (stale.length) console.log(`Đã xoá ${stale.length} token cũ`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((e) => {
    console.error(e.message ?? e);
    process.exit(1);
  });
}
