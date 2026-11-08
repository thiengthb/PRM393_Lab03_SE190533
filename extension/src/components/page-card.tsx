import { FileCode2, FlaskConical, RefreshCw } from 'lucide-react';

import { StepCard } from '@/components/step-card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { PageSnapshot } from '@/lib/attendance';

type Props = Readonly<{
  page: PageSnapshot | null;
  reading: boolean;
  disabled: boolean;
  onRead: () => void;
}>;

/** Step 1: read the open FAP page. */
export function PageCard({ page, reading, disabled, onRead }: Props) {
  const context = page?.context;
  return (
    <StepCard
      step={1}
      title="Đọc trang"
      state={page ? 'done' : 'active'}
      action={
        <Button
          variant={page ? 'outline' : 'default'}
          size="sm"
          onClick={onRead}
          disabled={disabled}
        >
          <RefreshCw className={reading ? 'animate-spin' : undefined} data-icon="inline-start" />
          {page ? 'Đọc lại' : 'Đọc trang'}
        </Button>
      }
    >
      {context ? (
        <div className="flex min-w-0 flex-col gap-1">
          <div className="flex min-w-0 items-center gap-2">
            <span className="truncate font-bold">
              {[context.course, context.group].filter(Boolean).join(' · ')}
            </span>
            <Badge variant="outline" className="shrink-0">
              {context.mode === 'fixture' ? (
                <FlaskConical data-icon="inline-start" />
              ) : (
                <FileCode2 data-icon="inline-start" />
              )}
              {context.mode === 'fixture' ? 'Giả lập' : 'HTML cục bộ'}
            </Badge>
          </div>
          <p className="truncate text-xs text-muted-foreground">
            {`${context.date} · Slot ${context.slot} · ${context.room} · ${page.rows.length} SV`}
          </p>
        </div>
      ) : (
        <p className="text-xs text-muted-foreground">Mở trang điểm danh FAP rồi bấm Đọc trang.</p>
      )}
    </StepCard>
  );
}
