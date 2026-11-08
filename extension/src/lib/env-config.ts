/**
 * Build-time configuration, parsed the same way by the manifest (Node, at build) and by the
 * extension pages (browser, at runtime). Pure: takes the raw env map, never reads globals, so the
 * manifest's host permissions and the runtime origin checks cannot drift apart.
 */
/** Firebase project của Attendo: web API key và project ID đều công khai (Rules mới là quyền). */
export type AttendoConfig = Readonly<{
  apiKey: string;
  projectId: string;
  /** Máy chạy Firebase Emulator (chỉ localhost / 127.0.0.1), dùng cho bản build test luồng. */
  emulatorHost: string | null;
}>;

export type ExtensionConfig = Readonly<{
  attendo: AttendoConfig | null;
  fixtureOrigins: readonly string[];
  googleClientId: string | null;
  extensionPublicKey: string | null;
}>;

type RawEnv = Readonly<Record<string, string | undefined>>;

const DEFAULT_FIXTURE_ORIGINS =
  'https://hereby-se190533-fap.web.app,https://hereby-se190533.web.app,http://localhost:4173,http://127.0.0.1:4173';

/** Project Firebase của Attendo. Web API key nằm trong .env (VITE_ATTENDO_API_KEY). */
const DEFAULT_ATTENDO_PROJECT_ID = 'hereby-se190533';

/** Origins that must never become a fixture/target origin, whatever the env says. */
const FORBIDDEN_HOST = /(^|\.)fpt\.edu\.vn$/i;

function parseOrigin(value: string, label: string): string {
  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error(`${label}: "${value}" is not a valid URL.`);
  }
  if (url.protocol !== 'https:' && !['localhost', '127.0.0.1'].includes(url.hostname)) {
    throw new Error(`${label}: "${value}" must use https (http is allowed only on localhost).`);
  }
  if (FORBIDDEN_HOST.test(url.hostname)) {
    throw new Error(`${label}: live FAP origins are disabled (docs/decisions.md D-001).`);
  }
  return url.origin;
}

function blankToNull(value: string | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

export function parseConfig(env: RawEnv): ExtensionConfig {
  // Thiếu hoặc rỗng VITE_ATTENDO_API_KEY thì tắt nguồn Attendo.
  const apiKey = blankToNull(env.VITE_ATTENDO_API_KEY);
  const projectId = blankToNull(env.VITE_ATTENDO_PROJECT_ID ?? DEFAULT_ATTENDO_PROJECT_ID);
  if (projectId && !/^[a-z0-9-]{4,40}$/.test(projectId)) {
    throw new Error('VITE_ATTENDO_PROJECT_ID must be a Firebase project ID.');
  }
  const emulatorHost = blankToNull(env.VITE_ATTENDO_EMULATOR_HOST);
  if (emulatorHost && !['localhost', '127.0.0.1'].includes(emulatorHost)) {
    throw new Error(
      'VITE_ATTENDO_EMULATOR_HOST must be localhost or 127.0.0.1 (test builds only).',
    );
  }
  const attendo = apiKey && projectId ? Object.freeze({ apiKey, projectId, emulatorHost }) : null;
  const fixtureOrigins = [
    ...new Set(
      (env.VITE_FIXTURE_ORIGINS ?? DEFAULT_FIXTURE_ORIGINS)
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean)
        .map((value) => parseOrigin(value, 'VITE_FIXTURE_ORIGINS')),
    ),
  ];
  const googleClientId = blankToNull(env.VITE_GOOGLE_CLIENT_ID);
  if (googleClientId && !/^[\w-]+\.apps\.googleusercontent\.com$/.test(googleClientId)) {
    throw new Error('VITE_GOOGLE_CLIENT_ID must look like <id>.apps.googleusercontent.com.');
  }
  return Object.freeze({
    attendo,
    fixtureOrigins: Object.freeze(fixtureOrigins),
    googleClientId,
    extensionPublicKey: blankToNull(env.VITE_EXTENSION_PUBLIC_KEY),
  });
}

/** Chrome match pattern for every path under an origin. */
export function originPattern(origin: string): string {
  return `${origin}/*`;
}

/** Origins của Firebase Auth và Firestore REST: Google thật, hoặc Firebase Emulator trên máy test. */
export function attendoApiOrigins(attendo: AttendoConfig): {
  auth: string;
  token: string;
  firestore: string;
} {
  if (attendo.emulatorHost) {
    const host = attendo.emulatorHost;
    return {
      auth: `http://${host}:9099/identitytoolkit.googleapis.com`,
      token: `http://${host}:9099/securetoken.googleapis.com`,
      firestore: `http://${host}:8080`,
    };
  }
  return {
    auth: 'https://identitytoolkit.googleapis.com',
    token: 'https://securetoken.googleapis.com',
    firestore: 'https://firestore.googleapis.com',
  };
}
