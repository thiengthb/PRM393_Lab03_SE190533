import { useId } from 'react';
import { Cloud, FileSpreadsheet, ListChecks, Sheet, X } from 'lucide-react';

import { StepCard } from '@/components/step-card';
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
        <span>Giữ nguyên SV không có trong tệp</span>
        <span className="text-xs text-muted-foreground">Khi tệp chỉ có một phần lớp.</span>
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
  if (!page) return <StepCard step={2} title="Chọn nguồn dữ liệu" state="locked" />;

  if (source) {
    return (
      <StepCard
        step={2}
        title="Chọn nguồn dữ liệu"
        state="done"
        action={
          <Button variant="ghost" size="sm" onClick={onClear} disabled={busy}>
            <X data-icon="inline-start" />
            Đổi
          </Button>
        }
      >
        <span className="truncate font-semibold">{source.label}</span>
        {supportsKeepMissing(source) && (
          <KeepMissingOption checked={keepMissing} disabled={busy} onChange={onKeepMissing} />
        )}
      </StepCard>
    );
  }

  const option = (
    <KeepMissingOption checked={keepMissing} disabled={busy} onChange={onKeepMissing} />
  );
  return (
    <StepCard step={2} title="Chọn nguồn dữ liệu">
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
          <p className="text-xs text-muted-foreground">Sửa từ trạng thái đang có trên trang.</p>
          <Button disabled={busy} onClick={() => onLoad(async () => pageAsSource(page))}>
            <ListChecks data-icon="inline-start" />
            Sửa thủ công
          </Button>
        </TabsContent>
      </Tabs>
    </StepCard>
  );
}
