import { useId } from 'react';
import { Cloud, FileSpreadsheet, ListChecks, Sheet, X } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import type { PageSnapshot, SourceBatch } from '@/lib/attendance';
import { pageAsSource, supportsKeepMissing } from '@/lib/draft';
import type { Lecturer } from '@/sidepanel/use-lecturer';

import { BackendSource } from './sources/backend-source';
import { FileSource } from './sources/file-source';
import { SheetSource } from './sources/sheet-source';

type Props = Readonly<{
  lecturer: Lecturer;
  page: PageSnapshot | null;
  source: SourceBatch | null;
  busy: boolean;
  keepMissing: boolean;
  onKeepMissing: (value: boolean) => void;
  onLoad: (load: () => Promise<SourceBatch>) => void;
  onClear: () => void;
}>;

/**
 * Opt-in for partial files/sheets (e.g. a list of absent students only). Off by default: a partial
 * file cannot be told apart from a truncated one, so the lecturer has to choose it knowingly.
 */
function KeepMissingOption({
  checked,
  disabled,
  onChange,
}: Readonly<{ checked: boolean; disabled: boolean; onChange: (value: boolean) => void }>) {
  const id = useId();
  return (
    <div className="flex items-start gap-2">
      <Checkbox
        id={id}
        checked={checked}
        disabled={disabled}
        onCheckedChange={(value) => onChange(value === true)}
      />
      <Label htmlFor={id} className="flex-col items-start gap-0.5 leading-snug font-normal">
        <span>Sinh viên không có trong nguồn: giữ trạng thái hiện tại</span>
        <span className="text-xs text-muted-foreground">
          Dùng khi tệp chỉ liệt kê một phần lớp. Mã ngoài danh sách trang vẫn bị từ chối.
        </span>
      </Label>
    </div>
  );
}

export function SourcePanel({
  lecturer,
  page,
  source,
  busy,
  keepMissing,
  onKeepMissing,
  onLoad,
  onClear,
}: Props) {
  if (source) {
    return (
      <section className="flex flex-col gap-2 rounded-xl bg-card px-3 py-2 ring-1 ring-foreground/10">
        <div className="flex items-center gap-2">
          <div className="flex min-w-0 flex-1 flex-col">
            <span className="text-xs text-muted-foreground">Nguồn dữ liệu</span>
            <span className="truncate font-medium">{source.label}</span>
          </div>
          <Button variant="ghost" size="sm" onClick={onClear} disabled={busy}>
            <X data-icon="inline-start" />
            Đổi nguồn
          </Button>
        </div>
        {supportsKeepMissing(source) && (
          <KeepMissingOption checked={keepMissing} disabled={busy} onChange={onKeepMissing} />
        )}
      </section>
    );
  }

  const option = (
    <KeepMissingOption checked={keepMissing} disabled={busy} onChange={onKeepMissing} />
  );
  return (
    <section
      aria-label="Chọn nguồn dữ liệu"
      className="rounded-xl bg-card p-3 ring-1 ring-foreground/10"
    >
      <Tabs defaultValue={lecturer.enabled ? 'backend' : 'file'}>
        <TabsList className="w-full">
          <TabsTrigger value="backend">
            <Cloud />
            Attendo
          </TabsTrigger>
          <TabsTrigger value="file">
            <FileSpreadsheet />
            Tệp
          </TabsTrigger>
          <TabsTrigger value="sheet">
            <Sheet />
            Sheets
          </TabsTrigger>
          <TabsTrigger value="page">
            <ListChecks />
            Thủ công
          </TabsTrigger>
        </TabsList>
        <TabsContent value="backend" className="pt-2">
          <BackendSource lecturer={lecturer} page={page} busy={busy} onLoad={onLoad} />
        </TabsContent>
        <TabsContent value="file" className="flex flex-col gap-3 pt-2">
          <FileSource page={page} busy={busy} onLoad={onLoad} />
          {option}
        </TabsContent>
        <TabsContent value="sheet" className="flex flex-col gap-3 pt-2">
          <SheetSource page={page} busy={busy} onLoad={onLoad} />
          {option}
        </TabsContent>
        <TabsContent value="page" className="flex flex-col gap-3 pt-2">
          <p className="text-xs text-muted-foreground">
            Bắt đầu từ trạng thái đang chọn trên trang rồi sửa từng sinh viên hoặc đặt hàng loạt.
          </p>
          <Button
            disabled={busy || !page}
            onClick={() => page && onLoad(async () => pageAsSource(page))}
          >
            <ListChecks data-icon="inline-start" />
            Sửa thủ công
          </Button>
        </TabsContent>
      </Tabs>
    </section>
  );
}
