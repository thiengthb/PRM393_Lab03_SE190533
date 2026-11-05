import { CircleAlert, CircleCheck, Info, TriangleAlert } from 'lucide-react';

import { ActionBar } from '@/components/action-bar';
import { DraftPanel } from '@/components/draft-panel';
import { PageCard } from '@/components/page-card';
import { SourcePanel } from '@/components/source-panel';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Toaster } from '@/components/ui/sonner';

import { useLecturer } from './use-lecturer';
import { useWorkflow } from './use-workflow';

const NOTICE_ICON = {
  default: Info,
  success: CircleCheck,
  warning: TriangleAlert,
  destructive: CircleAlert,
} as const;

export function App() {
  const workflow = useWorkflow();
  const lecturer = useLecturer();
  const { state } = workflow;
  const NoticeIcon = state.notice ? NOTICE_ICON[state.notice.tone] : null;
  const editing = Boolean(state.page && state.rows);

  return (
    <div className="flex h-dvh flex-col">
      <header className="flex items-center gap-2.5 border-b px-4 py-2.5">
        <div
          aria-hidden
          className="grid size-8 place-items-center rounded-lg bg-primary text-xs font-bold text-primary-foreground"
        >
          FA
        </div>
        <div className="flex min-w-0 flex-col">
          <h1 className="truncate text-base leading-tight font-semibold">FAP Attendance</h1>
          <span className="truncate text-xs text-muted-foreground">
            Xem trước, điền và kiểm tra. Bạn tự bấm Save.
          </span>
        </div>
      </header>

      <main className="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto px-4 py-3">
        <PageCard
          page={state.page}
          reading={state.busy === 'read'}
          disabled={state.busy !== null}
          onRead={() => void workflow.read()}
        />
        {state.notice && NoticeIcon && (
          <Alert variant={state.notice.tone}>
            <NoticeIcon />
            <AlertDescription>{state.notice.text}</AlertDescription>
          </Alert>
        )}
        {state.page && (
          <SourcePanel
            lecturer={lecturer}
            page={state.page}
            source={state.source}
            busy={state.busy !== null}
            keepMissing={state.keepMissing}
            onKeepMissing={workflow.setKeepMissing}
            onLoad={(load) => void workflow.loadSource(load)}
            onClear={workflow.clearSource}
          />
        )}
        {state.page && state.rows && (
          <DraftPanel
            page={state.page}
            rows={state.rows}
            checks={state.checks}
            kept={state.kept}
            disabled={state.busy !== null}
            onStatus={workflow.setStatus}
            onSetAll={workflow.setAll}
          />
        )}
      </main>

      {editing && state.page && (
        <ActionBar
          mode={state.page.context.mode}
          ready={editing}
          confirmed={state.confirmed}
          busy={state.busy}
          onConfirm={workflow.confirm}
          onApply={(action) => void workflow.apply(action)}
        />
      )}
      <Toaster position="top-center" />
    </div>
  );
}
