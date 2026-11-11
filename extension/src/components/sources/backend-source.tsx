import { useEffect, useState, type FormEvent } from 'react';
import { CloudDownload, LogIn, LogOut } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Separator } from '@/components/ui/separator';
import type { PageSnapshot, SourceBatch } from '@/lib/attendance';
import { findClosedSlots, loadClosedSlot, type ClosedSlot } from '@/lib/sources/backend';
import { errorMessage } from '@/lib/utils';
import type { Lecturer } from '@/sidepanel/use-lecturer';

import { SourceNote } from './source-note';

type Props = Readonly<{
  lecturer: Lecturer;
  page: PageSnapshot | null;
  busy: boolean;
  onLoad: (load: () => Promise<SourceBatch>) => void;
}>;

export function BackendSource({ lecturer, page, busy, onLoad }: Props) {
  if (!lecturer.enabled) {
    return <SourceNote>Bản này chưa bật nguồn Attendo.</SourceNote>;
  }
  if (lecturer.restoring) return <SourceNote>Đang khôi phục phiên đăng nhập...</SourceNote>;
  if (!lecturer.session) return <SignInForm lecturer={lecturer} />;
  return <BatchLoader lecturer={lecturer} page={page} busy={busy} onLoad={onLoad} />;
}

function SignInForm({ lecturer }: Readonly<{ lecturer: Lecturer }>) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function run(action: () => Promise<void>) {
    setPending(true);
    setError(null);
    try {
      await action();
    } catch (cause) {
      setError(errorMessage(cause, 'Đăng nhập thất bại.'));
    } finally {
      setPassword('');
      setPending(false);
    }
  }

  function submit(event: FormEvent) {
    event.preventDefault();
    void run(() => lecturer.signIn(email, password));
  }

  return (
    <form className="flex flex-col gap-3" onSubmit={submit}>
      <p className="text-xs text-muted-foreground">
        Đăng nhập tài khoản giảng viên Attendo để lấy bản đã chốt. Không lưu mật khẩu.
      </p>
      {lecturer.googleEnabled && (
        <>
          <Button
            type="button"
            variant="outline"
            disabled={pending}
            onClick={() => void run(lecturer.signInWithGoogle)}
          >
            <GoogleMark />
            Đăng nhập bằng Google
          </Button>
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            <Separator className="flex-1" />
            hoặc dùng email
            <Separator className="flex-1" />
          </div>
        </>
      )}
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="login-email">Email</Label>
        <Input
          id="login-email"
          type="email"
          autoComplete="username"
          required
          value={email}
          onChange={(event) => setEmail(event.target.value)}
        />
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="login-password">Mật khẩu</Label>
        <Input
          id="login-password"
          type="password"
          autoComplete="current-password"
          required
          minLength={6}
          maxLength={128}
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
      </div>
      {error && <p className="text-xs text-alert">{error}</p>}
      <Button type="submit" disabled={pending}>
        <LogIn data-icon="inline-start" />
        {pending ? 'Đang đăng nhập...' : 'Đăng nhập'}
      </Button>
    </form>
  );
}

/** Chữ G bốn màu theo hướng dẫn thương hiệu của Google cho nút đăng nhập. */
function GoogleMark() {
  return (
    <svg data-icon="inline-start" viewBox="0 0 48 48" aria-hidden="true" className="size-4">
      <path
        fill="#EA4335"
        d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
      />
      <path
        fill="#4285F4"
        d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
      />
      <path
        fill="#FBBC05"
        d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
      />
      <path
        fill="#34A853"
        d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
      />
    </svg>
  );
}

function BatchLoader({ lecturer, page, busy, onLoad }: Props) {
  const session = lecturer.session!;
  const course = page?.context.course ?? '';
  const group = page?.context.group ?? '';
  const key = `${course}|${group}`;
  // Kết quả gắn với khoá môn|lớp đã hỏi: khoá đổi thì coi như đang tải, không cần setState đồng bộ.
  const [result, setResult] = useState<{
    key: string;
    slots: ClosedSlot[] | null;
    error: string | null;
  }>({ key: '', slots: null, error: null });
  const [picked, setPicked] = useState('');

  useEffect(() => {
    if (!course || !group) return;
    let alive = true;
    findClosedSlots(session, { course, group })
      .then((list) => alive && setResult({ key, slots: list, error: null }))
      .catch(
        (cause: unknown) =>
          alive &&
          setResult({ key, slots: null, error: errorMessage(cause, 'Không tải được slot.') }),
      );
    return () => {
      alive = false;
    };
  }, [session, course, group, key]);

  const current = result.key === key ? result : { slots: null, error: null };
  const slots = current.slots;
  const error = current.error;
  // Mặc định chọn slot trùng ngày và slot của trang, không có thì slot mới nhất.
  const match = slots?.find((s) => s.date === page?.context.date && s.slot === page?.context.slot);
  const chosen = slots?.some((s) => s.id === picked) ? picked : ((match ?? slots?.[0])?.id ?? '');
  const slot = slots?.find((s) => s.id === chosen) ?? null;
  return (
    <div className="flex flex-col gap-3">
      <div className="flex min-w-0 items-center gap-2">
        <div className="flex min-w-0 flex-1 flex-col">
          <span className="truncate font-medium">{session.user.displayName}</span>
          <span className="truncate text-xs text-muted-foreground">{session.user.email}</span>
        </div>
        <Button variant="ghost" size="sm" onClick={() => void lecturer.signOut()}>
          <LogOut data-icon="inline-start" />
          Đăng xuất
        </Button>
      </div>
      {!page && <SourceNote>Đọc trang FAP trước.</SourceNote>}
      {page && slots === null && !error && <SourceNote>Đang tìm slot đã chốt...</SourceNote>}
      {error && <p className="text-xs text-alert">{error}</p>}
      {slots?.length === 0 && (
        <SourceNote>
          Chưa có slot đã chốt của {course} · {group}. Chốt trên app Attendo trước.
        </SourceNote>
      )}
      {slots && slots.length > 0 && (
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="attendo-slot">Slot đã chốt</Label>
          <select
            id="attendo-slot"
            className="h-9 rounded-lg border border-input bg-background px-2 text-sm outline-none focus-visible:border-ring focus-visible:ring-1 focus-visible:ring-ring"
            value={chosen}
            onChange={(event) => setPicked(event.target.value)}
          >
            {slots.map((s) => (
              <option key={s.id} value={s.id}>
                {s.date} · slot {s.slot} · {s.room}
              </option>
            ))}
          </select>
        </div>
      )}
      <Button
        disabled={busy || !page || !slot}
        onClick={() => slot && onLoad(() => loadClosedSlot(session, slot))}
      >
        <CloudDownload data-icon="inline-start" />
        Lấy bản đã chốt
      </Button>
    </div>
  );
}
