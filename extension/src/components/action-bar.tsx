import { FlaskConical, PenLine, ScanSearch } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import type { PageMode } from '@/lib/attendance';
import type { ApplyAction } from '@/lib/page-bridge';
import type { Busy } from '@/sidepanel/workflow';

type Props = Readonly<{
  mode: PageMode;
  ready: boolean;
  confirmed: boolean;
  busy: Busy;
  onConfirm: (value: boolean) => void;
  onApply: (action: ApplyAction) => void;
}>;

export function ActionBar({ mode, ready, confirmed, busy, onConfirm, onApply }: Props) {
  const locked = !ready || busy !== null;
  return (
    <footer className="flex flex-col gap-2 border-t bg-card px-3 pt-3 pb-3">
      <div className="flex items-start gap-2">
        <Checkbox
          id="confirm-changes"
          checked={confirmed}
          disabled={locked}
          onCheckedChange={(value) => onConfirm(value === true)}
        />
        <Label htmlFor="confirm-changes" className="leading-snug font-normal">
          Tôi đã kiểm tra danh sách
        </Label>
      </div>
      <div className="grid grid-cols-[1fr_auto] gap-2">
        <Button disabled={locked || !confirmed} onClick={() => onApply('FAP_EXT_FILL')}>
          <PenLine data-icon="inline-start" />
          {busy === 'FAP_EXT_FILL' ? 'Đang điền...' : 'Điền vào trang'}
        </Button>
        <Button variant="outline" disabled={locked} onClick={() => onApply('FAP_EXT_VERIFY')}>
          <ScanSearch data-icon="inline-start" />
          Kiểm tra
        </Button>
        {mode === 'fixture' && (
          <Button
            variant="secondary"
            className="col-span-2"
            disabled={locked || !confirmed}
            onClick={() => onApply('FAP_EXT_FILL_SAVE')}
          >
            <FlaskConical data-icon="inline-start" />
            Điền và lưu giả lập
          </Button>
        )}
      </div>
      <p className="text-xs text-muted-foreground">
        {mode === 'fixture' ? 'Giả lập, không gửi gì lên FAP.' : 'Bạn tự bấm Save trên FAP.'}
      </p>
    </footer>
  );
}
