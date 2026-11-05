import { z } from 'zod';

/** Exactly two statuses. There is no LATE (product rule inherited from the assistant project). */
export const attendanceStatusSchema = z.enum(['ATTEND', 'ABSENT']);
export type AttendanceStatus = z.infer<typeof attendanceStatusSchema>;

/** `fixture` = versioned synthetic mock-fap-v2; `local` = a saved lecturer HTML opened via file://. */
export const pageModeSchema = z.enum(['fixture', 'local']);
export type PageMode = z.infer<typeof pageModeSchema>;

export const pageContextSchema = z.object({
  mode: pageModeSchema,
  campus: z.string(),
  course: z.string(),
  sessionId: z.string(),
  group: z.string(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
  slot: z.string(),
  room: z.string(),
});
export type PageContext = z.infer<typeof pageContextSchema>;

export const pageRowSchema = z.object({
  studentCode: z.string().min(1),
  name: z.string(),
  currentStatus: attendanceStatusSchema,
});
export type PageRow = z.infer<typeof pageRowSchema>;

export const pageSnapshotSchema = z.object({
  context: pageContextSchema,
  rows: z.array(pageRowSchema).min(1),
});
export type PageSnapshot = z.infer<typeof pageSnapshotSchema>;

export const draftRowSchema = z.object({
  studentCode: z.string().min(1),
  status: attendanceStatusSchema,
});
export type DraftRow = z.infer<typeof draftRowSchema>;

export const mismatchSchema = z.object({
  studentCode: z.string(),
  expected: attendanceStatusSchema,
  actual: attendanceStatusSchema,
});

export const verifyResultSchema = z.object({
  total: z.number().int().nonnegative(),
  matched: z.number().int().nonnegative(),
  mismatches: z.array(mismatchSchema),
  page: pageSnapshotSchema,
  changed: z.number().int().nonnegative().optional(),
  saved: z.boolean().optional(),
});
export type VerifyResult = z.infer<typeof verifyResultSchema>;

/** Context fields a source may carry. A null/absent field is simply not checked. */
export const CONTEXT_FIELDS = ['campus', 'course', 'group', 'date', 'slot', 'room'] as const;
export type ContextField = (typeof CONTEXT_FIELDS)[number];
export type BatchContext = Partial<Record<ContextField, string | null>>;

export type SourceKind = 'backend' | 'file' | 'sheet' | 'page';

export type SourceBatch = Readonly<{
  kind: SourceKind;
  /** Human-readable origin of the data, e.g. file name or "Revision 3". */
  label: string;
  context: BatchContext;
  rows: readonly DraftRow[];
  /** Present for backend batches; shown so the lecturer can match it to Lecturer Desktop. */
  revision?: number;
  checksum?: string;
}>;

export const STATUS_LABEL: Record<AttendanceStatus, string> = {
  ATTEND: 'Có mặt',
  ABSENT: 'Vắng',
};

export const CONTEXT_LABEL: Record<ContextField, string> = {
  campus: 'Campus',
  course: 'Môn',
  group: 'Lớp',
  date: 'Ngày',
  slot: 'Slot',
  room: 'Phòng',
};
