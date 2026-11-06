import type { ReactNode } from 'react';
import { Check } from 'lucide-react';

import { cn } from '@/lib/utils';

type Props = Readonly<{
  step: number;
  title: string;
  /** `done` shows a check instead of the number; `locked` greys out a step that cannot start yet. */
  state?: 'active' | 'done' | 'locked';
  action?: ReactNode;
  className?: string;
  children?: ReactNode;
}>;

/**
 * One numbered step of the fill flow (Đọc trang, Chọn nguồn, Kiểm tra). Same card shape as the
 * Attendo app: white card, thin border, no shadow, radius 8.
 */
export function StepCard({ step, title, state = 'active', action, className, children }: Props) {
  const titleId = `step-${step}-title`;
  return (
    <section
      aria-labelledby={titleId}
      className={cn(
        'flex flex-col gap-3 rounded-xl border bg-card p-3',
        state === 'locked' && 'bg-muted',
        className,
      )}
    >
      <div className="flex min-w-0 items-center gap-2.5">
        <span
          aria-hidden
          className={cn(
            'grid size-6 shrink-0 place-items-center rounded-full text-xs font-semibold tabular-nums',
            state === 'active' && 'bg-primary text-primary-foreground',
            state === 'done' && 'bg-primary-soft text-on-primary-soft',
            state === 'locked' && 'bg-border text-muted-foreground',
          )}
        >
          {state === 'done' ? <Check className="size-3.5" strokeWidth={3} /> : step}
        </span>
        <h2
          id={titleId}
          className={cn(
            'min-w-0 flex-1 truncate text-base font-bold',
            state === 'locked' && 'font-semibold text-muted-foreground',
          )}
        >
          {title}
        </h2>
        {action}
      </div>
      {children}
    </section>
  );
}
