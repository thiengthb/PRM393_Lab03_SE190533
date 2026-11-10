import { CircleAlert, CircleCheck, Info, TriangleAlert } from 'lucide-react';

import { ActionBar } from '@/components/action-bar';
import { BrandWordmark } from '@/components/brand-wordmark';
import { DraftPanel } from '@/components/draft-panel';
import { PageCard } from '@/components/page-card';
import { SourcePanel } from '@/components/source-panel';
import { StepCard } from '@/components/step-card';
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
      <header className="flex items-baseline gap-2 border-b bg-card px-3 py-3">
        <h1 className="flex items-baseline gap-2">
          <BrandWordmark className="text-xl" />
          <span className="text-sm font-medium text-muted-foreground">cho FAP</span>
        </h1>
      </header>

      <main className="flex min-h-0 flex-1 flex-col gap-3 overflow-y-auto px-3 py-3">
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
        {state.page && state.rows ? (
          <DraftPanel
            page={state.page}
            rows={state.rows}
            checks={state.checks}
            kept={state.kept}
            disabled={state.busy !== null}
            onStatus={workflow.setStatus}
            onSetAll={workflow.setAll}
          />
        ) : (
          <StepCard step={3} title="Kiểm tra bản nháp" state="locked" />
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
      {/* Below the header so the toast never covers the logo (LOI-07); the side panel is
          narrower than sonner's mobile breakpoint, so mobileOffset is the one that applies. */}
      <Toaster position="top-center" offset={{ top: 60 }} mobileOffset={{ top: 60 }} />
    </div>
  );
}
