import { useEffect, useState, type FormEvent } from 'react';
import { CloudDownload, LogIn, LogOut } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
    return <SourceNote>Bản build này đã tắt nguồn Attendo (VITE_HEREBY_API_KEY rỗng).</SourceNote>;
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

  async function submit(event: FormEvent) {
    event.preventDefault();
    setPending(true);
    setError(null);
    try {
      await lecturer.signIn(email, password);
    } catch (cause) {
      setError(errorMessage(cause, 'Đăng nhập thất bại.'));
    } finally {
      setPassword('');
      setPending(false);
    }
  }

  return (
    <form className="flex flex-col gap-3" onSubmit={submit}>
      <p className="text-xs text-muted-foreground">
        Đăng nhập tài khoản giảng viên Attendo để lấy bản điểm danh đã chốt trên app. Mật khẩu không
        được lưu; phiên tự hết khi đóng trình duyệt.
      </p>
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
      {!page && <SourceNote>Mở trang điểm danh FAP để tìm slot tương ứng.</SourceNote>}
      {page && slots === null && !error && <SourceNote>Đang tìm slot đã chốt...</SourceNote>}
      {error && <p className="text-xs text-alert">{error}</p>}
      {slots?.length === 0 && (
        <SourceNote>
          Chưa có slot đã chốt của {course} · {group}. Chốt điểm danh trên app Attendo trước.
        </SourceNote>
      )}
      {slots && slots.length > 0 && (
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="hereby-slot">Slot đã chốt trên Attendo</Label>
          <select
            id="hereby-slot"
            className="h-9 rounded-md border border-input bg-background px-2 text-sm"
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
