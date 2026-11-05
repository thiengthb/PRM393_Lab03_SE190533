import { memo, useDeferredValue, useMemo, useState } from 'react';
import { CircleCheck, CircleMinus, Search } from 'lucide-react';

import { StepCard } from '@/components/step-card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  CONTEXT_LABEL,
  STATUS_LABEL,
  type AttendanceStatus,
  type DraftRow,
  type PageRow,
  type PageSnapshot,
} from '@/lib/attendance';
import { summarize, type ContextCheck } from '@/lib/draft';
import { cn } from '@/lib/utils';

type Props = Readonly<{
  page: PageSnapshot;
  rows: readonly DraftRow[];
  checks: readonly ContextCheck[];
  kept: readonly string[];
  disabled: boolean;
  onStatus: (studentCode: string, status: AttendanceStatus) => void;
  onSetAll: (status: AttendanceStatus, codes?: readonly string[]) => void;
}>;

function Stat({ label, value, tone }: Readonly<{ label: string; value: number; tone?: string }>) {
  return (
    <div className="flex min-w-0 flex-col items-center rounded-lg bg-muted px-2 py-1.5">
      <span className={cn('text-base font-extrabold tabular-nums', tone)}>{value}</span>
      <span className="truncate text-xs text-muted-foreground">{label}</span>
    </div>
  );
}

export function DraftPanel({ page, rows, checks, kept, disabled, onStatus, onSetAll }: Props) {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query);
  const summary = summarize(page, rows);
  const pageRows = useMemo(() => new Map(page.rows.map((row) => [row.studentCode, row])), [page]);
  const visible = useMemo(() => {
    const needle = deferredQuery.trim().toLocaleLowerCase('vi');
    return rows.filter((row) => {
      if (!needle) return true;
      const name = pageRows.get(row.studentCode)?.name ?? '';
      return `${row.studentCode} ${name}`.toLocaleLowerCase('vi').includes(needle);
    });
  }, [rows, pageRows, deferredQuery]);
  const matched = checks.filter((check) => check.result === 'match');
  const filtered = visible.length !== rows.length;
  const keptSet = useMemo(() => new Set(kept), [kept]);

  return (
    <StepCard step={3} title="Kiểm tra bản nháp" className="shrink-0">
      <div className="grid grid-cols-4 gap-2">
        <Stat label="Sĩ số" value={summary.total} />
        <Stat label="Có mặt" value={summary.attend} tone="text-ok" />
        <Stat label="Vắng" value={summary.absent} tone="text-alert" />
        <Stat
          label="Thay đổi"
          value={summary.changed}
          tone={summary.changed ? 'text-warn' : undefined}
        />
      </div>
      <p className="text-xs text-muted-foreground">
        {matched.length
          ? `Khớp ${matched.map((check) => CONTEXT_LABEL[check.field]).join(', ')}.`
          : 'Chỉ đối chiếu danh sách sinh viên.'}
        {kept.length > 0 && ` ${kept.length} SV giữ nguyên.`}
      </p>
      <div className="flex items-center gap-2">
        <div className="relative min-w-0 flex-1">
          <Search className="pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            type="search"
            aria-label="Tìm sinh viên"
            placeholder="Tìm SV"
            className="pl-8"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </div>
        <Button
          variant="outline"
          size="sm"
          disabled={disabled}
          onClick={() =>
            onSetAll('ATTEND', filtered ? visible.map((row) => row.studentCode) : undefined)
          }
        >
          {filtered ? 'Lọc: có mặt' : 'Tất cả có mặt'}
        </Button>
        <Button
          variant="outline"
          size="sm"
          disabled={disabled}
          onClick={() =>
            onSetAll('ABSENT', filtered ? visible.map((row) => row.studentCode) : undefined)
          }
        >
          {filtered ? 'Lọc: vắng' : 'Tất cả vắng'}
        </Button>
      </div>
      <ul className="flex flex-col divide-y rounded-lg border">
        {visible.map((row) => (
          <DraftItem
            key={row.studentCode}
            row={row}
            pageRow={pageRows.get(row.studentCode)}
            kept={keptSet.has(row.studentCode)}
            disabled={disabled}
            onStatus={onStatus}
          />
        ))}
        {!visible.length && (
          <li className="px-3 py-6 text-center text-xs text-muted-foreground">
            Không có sinh viên khớp tìm kiếm.
          </li>
        )}
      </ul>
    </StepCard>
  );
}

const DraftItem = memo(function DraftItem({
  row,
  pageRow,
  kept,
  disabled,
  onStatus,
}: Readonly<{
  row: DraftRow;
  pageRow: PageRow | undefined;
  kept: boolean;
  disabled: boolean;
  onStatus: (studentCode: string, status: AttendanceStatus) => void;
}>) {
  const changed = pageRow?.currentStatus !== row.status;
  return (
    <li className={cn('flex items-center gap-2 px-3 py-1.5', changed && 'bg-warn-soft')}>
      <div className="flex min-w-0 flex-1 flex-col">
        <span className="truncate text-xs font-bold tabular-nums">{row.studentCode}</span>
        <span className="truncate text-xs text-muted-foreground">
          {pageRow?.name}
          {changed && pageRow ? ` · đang là ${STATUS_LABEL[pageRow.currentStatus]}` : ''}
          {kept && !changed ? ' · giữ nguyên' : ''}
        </span>
      </div>
      <div
        role="radiogroup"
        aria-label={`Trạng thái ${row.studentCode}`}
        className="flex shrink-0 rounded-lg bg-muted p-0.5"
      >
        {(['ATTEND', 'ABSENT'] as const).map((status) => {
          const active = row.status === status;
          return (
            <button
              key={status}
              type="button"
              role="radio"
              aria-checked={active}
              disabled={disabled}
              onClick={() => onStatus(row.studentCode, status)}
              className={cn(
                'inline-flex h-7 items-center gap-1 rounded-md px-2 text-xs font-medium text-muted-foreground transition-colors outline-none hover:text-foreground focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50',
                active &&
                  status === 'ATTEND' &&
                  'bg-ok text-white hover:text-white dark:text-background dark:hover:text-background',
                active &&
                  status === 'ABSENT' &&
                  'bg-alert text-white hover:text-white dark:text-background dark:hover:text-background',
              )}
            >
              {status === 'ATTEND' ? (
                <CircleCheck className="size-3.5" />
              ) : (
                <CircleMinus className="size-3.5" />
              )}
              {STATUS_LABEL[status]}
            </button>
          );
        })}
      </div>
    </li>
  );
});
