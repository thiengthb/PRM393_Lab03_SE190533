import { z } from 'zod';

import { draftRowSchema, pageSnapshotSchema, verifyResultSchema } from './attendance';

/** Every message the side panel sends to the injected page adapter. */
export const pageRequestSchema = z.discriminatedUnion('type', [
  z.object({ type: z.literal('FAP_EXT_READ') }),
  z.object({
    type: z.enum(['FAP_EXT_FILL', 'FAP_EXT_VERIFY', 'FAP_EXT_FILL_SAVE']),
    changes: z.array(draftRowSchema),
    expectedPage: pageSnapshotSchema,
  }),
]);
export type PageRequest = z.infer<typeof pageRequestSchema>;

export const pageResponseSchemas = {
  FAP_EXT_READ: pageSnapshotSchema,
  FAP_EXT_FILL: verifyResultSchema,
  FAP_EXT_VERIFY: verifyResultSchema,
  FAP_EXT_FILL_SAVE: verifyResultSchema,
} as const;

export type PageResponse<T> = { ok: true; data: T } | { ok: false; error: string };
