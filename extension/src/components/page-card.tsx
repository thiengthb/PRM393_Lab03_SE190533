import { FileCode2, FlaskConical, RefreshCw } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { PageSnapshot } from '@/lib/attendance';

type Props = Readonly<{
  page: PageSnapshot | null;
  reading: boolean;
  disabled: boolean;
  onRead: () => void;
}>;

export function PageCard({ page, reading, disabled, onRead }: Props) {
  const context = page?.context;
  return (
    <section
      aria-labelledby="page-card-title"
      className="flex items-start gap-3 rounded-xl bg-card p-3 ring-1 ring-foreground/10"
    >
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <div className="flex min-w-0 items-center gap-2">
          <h2 id="page-card-title" className="truncate text-base font-medium">
            {context
              ? [context.course, context.group].filter(Boolean).join(' / ')
              : 'Chưa đọc trang'}
          </h2>
          {context && (
            <Badge variant="outline" className="shrink-0">
              {context.mode === 'fixture' ? (
                <FlaskConical data-icon="inline-start" />
              ) : (
                <FileCode2 data-icon="inline-start" />
              )}
              {context.mode === 'fixture' ? 'Giả lập' : 'HTML cục bộ'}
            </Badge>
          )}
        </div>
        <p className="line-clamp-2 text-xs text-muted-foreground">
          {context
            ? `${context.campus} · ${context.date} · Slot ${context.slot} · ${context.room} · ${page.rows.length} sinh viên`
            : 'Mở trang điểm danh FAP giả lập hoặc file HTML đã lưu, rồi bấm Đọc trang.'}
        </p>
      </div>
      <Button variant="outline" size="sm" onClick={onRead} disabled={disabled}>
        <RefreshCw className={reading ? 'animate-spin' : undefined} data-icon="inline-start" />
        Đọc trang
      </Button>
    </section>
  );
}
