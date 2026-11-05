import { useRef } from 'react';
import { Download, FileUp } from 'lucide-react';

import { Button } from '@/components/ui/button';
import type { PageSnapshot, SourceBatch } from '@/lib/attendance';
import { buildTemplateCsv } from '@/lib/template';
import { ACCEPTED_FILE_TYPES, readAttendanceFile } from '@/lib/sources/file-import';

type Props = Readonly<{
  page: PageSnapshot | null;
  busy: boolean;
  onLoad: (load: () => Promise<SourceBatch>) => void;
}>;

function downloadTemplate(page: PageSnapshot) {
  const blob = new Blob([buildTemplateCsv(page)], { type: 'text/csv;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `diem-danh-${page.context.group}-${page.context.date}-slot${page.context.slot}.csv`;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function FileSource({ page, busy, onLoad }: Props) {
  const input = useRef<HTMLInputElement>(null);

  return (
    <div className="flex flex-col gap-3">
      <p className="text-xs text-muted-foreground">
        CSV hoặc XLSX có cột mã SV và cột trạng thái. Không chắc định dạng thì tải tệp mẫu.
      </p>
      <input
        ref={input}
        type="file"
        accept={ACCEPTED_FILE_TYPES}
        className="sr-only"
        aria-label="Chọn tệp điểm danh"
        onChange={(event) => {
          const file = event.target.files?.[0];
          event.target.value = '';
          if (file) onLoad(() => readAttendanceFile(file));
        }}
      />
      <div className="flex flex-wrap gap-2">
        <Button disabled={busy || !page} onClick={() => input.current?.click()}>
          <FileUp data-icon="inline-start" />
          Chọn tệp
        </Button>
        <Button variant="outline" disabled={!page} onClick={() => page && downloadTemplate(page)}>
          <Download data-icon="inline-start" />
          Tệp mẫu
        </Button>
      </div>
    </div>
  );
}
