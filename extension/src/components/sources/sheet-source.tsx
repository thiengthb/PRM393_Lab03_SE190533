import { useEffect, useState } from 'react';
import { Sheet, Unplug } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import type { PageSnapshot, SourceBatch } from '@/lib/attendance';
import {
  forgetGoogleToken,
  hasGoogleToken,
  isSheetsEnabled,
  readAttendanceSheet,
} from '@/lib/sources/google-sheets';

import { SourceNote } from './source-note';

type Props = Readonly<{
  page: PageSnapshot | null;
  busy: boolean;
  onLoad: (load: () => Promise<SourceBatch>) => void;
}>;

export function SheetSource({ page, busy, onLoad }: Props) {
  const [link, setLink] = useState('');
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    if (isSheetsEnabled()) void hasGoogleToken().then(setConnected);
  }, [busy]);

  if (!isSheetsEnabled()) {
    return (
      <SourceNote>
        Bản này chưa bật Google Sheets. Tải Sheet về CSV hoặc XLSX rồi dùng tab Tệp.
      </SourceNote>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="sheet-link">Link Google Sheet (đúng tab)</Label>
        <Input
          id="sheet-link"
          type="url"
          placeholder="https://docs.google.com/spreadsheets/d/...#gid=..."
          value={link}
          onChange={(event) => setLink(event.target.value)}
        />
      </div>
      <p className="text-xs text-muted-foreground">Chỉ đọc, không ghi gì lên Sheet.</p>
      <div className="flex flex-wrap gap-2">
        <Button
          disabled={busy || !page || !link.trim()}
          onClick={() => onLoad(() => readAttendanceSheet(link))}
        >
          <Sheet data-icon="inline-start" />
          {connected ? 'Đọc Sheet' : 'Kết nối Google và đọc'}
        </Button>
        {connected && (
          <Button
            variant="ghost"
            onClick={() => void forgetGoogleToken().then(() => setConnected(false))}
          >
            <Unplug data-icon="inline-start" />
            Ngắt kết nối
          </Button>
        )}
      </div>
    </div>
  );
}
