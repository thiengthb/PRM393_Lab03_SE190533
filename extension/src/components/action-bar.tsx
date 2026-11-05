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
    <footer className="flex flex-col gap-2 border-t bg-background px-4 pt-3 pb-4">
      <div className="flex items-start gap-2">
        <Checkbox
          id="confirm-changes"
          checked={confirmed}
          disabled={locked}
          onCheckedChange={(value) => onConfirm(value === true)}
        />
        <Label htmlFor="confirm-changes" className="leading-snug font-normal">
          Tôi đã kiểm tra danh sách và các thay đổi
        </Label>
      </div>
      <div className="flex flex-wrap gap-2">
        <Button
          className="flex-1"
          disabled={locked || !confirmed}
          onClick={() => onApply('FAP_EXT_FILL')}
        >
          <PenLine data-icon="inline-start" />
          {busy === 'FAP_EXT_FILL' ? 'Đang điền...' : 'Chỉ điền'}
        </Button>
        {mode === 'fixture' && (
          <Button
            variant="secondary"
            className="flex-1"
            disabled={locked || !confirmed}
            onClick={() => onApply('FAP_EXT_FILL_SAVE')}
          >
            <FlaskConical data-icon="inline-start" />
            Điền và lưu giả lập
          </Button>
        )}
        <Button variant="outline" disabled={locked} onClick={() => onApply('FAP_EXT_VERIFY')}>
          <ScanSearch data-icon="inline-start" />
          Kiểm tra
        </Button>
      </div>
      <p className="text-xs text-muted-foreground">
        {mode === 'fixture'
          ? 'Chỉ dữ liệu giả lập; không gửi gì lên FAP.'
          : 'Chỉ đổi lựa chọn trong tab; không sửa file và không bấm Save.'}
      </p>
    </footer>
  );
}
