# Map

## Flow

```text
toolbar click / Alt+Shift+F
  -> background/service-worker.ts   opens the side panel (no state, no network)
  -> sidepanel/use-workflow.ts      read(): inject content/index.ts (IIFE) into the active tab
       -> content/fap-v2-adapter.ts read() -> PageSnapshot { context, rows }
  -> source (one of four)           -> SourceBatch { context?, rows }
       backend   lib/sources/backend.ts        POST /auth/password, GET /extension/approved-batches/{id}
       file      lib/sources/file-import.ts    CSV/TSV (papaparse) or XLSX (read-excel-file) -> lib/grid.ts
       sheets    lib/sources/google-sheets.ts  launchWebAuthFlow + Sheets values API -> lib/grid.ts
       manual    lib/draft.ts pageAsSource     current page statuses
  -> lib/draft.ts buildDraft        context check + exact roster match -> editable rows (page order)
  -> lecturer edits, ticks the confirmation
  -> page-bridge applyToPage        FILL | VERIFY | FILL_SAVE (fixture only)
       -> adapter preflight (re-inspect, compare with snapshot) -> set radios -> verify
  -> lecturer reviews the page and presses Save on FAP themself
```

## Files

| Path                            | Role                                                                    |
| ------------------------------- | ----------------------------------------------------------------------- |
| `manifest.config.ts`            | Manifest from env; permissions only for configured features             |
| `src/lib/env-config.ts`         | Parses `VITE_*` once for manifest and runtime (no drift)                |
| `src/lib/attendance.ts`         | zod schemas and types shared by panel and adapter                       |
| `src/lib/messages.ts`           | Panel to adapter message contract                                       |
| `src/lib/draft.ts`              | Context check, roster match, summary                                    |
| `src/lib/grid.ts`, `status.ts`  | Header detection, status vocabulary for files and sheets                |
| `src/lib/template.ts`           | CSV template generated from the page (round-trips through the importer) |
| `src/lib/page-bridge.ts`        | `executeScript` + typed `sendMessage`, file-URL permission check        |
| `src/content/fap-v2-adapter.ts` | The only code that touches the FAP DOM                                  |
| `src/sidepanel/workflow.ts`     | Pure reducer: confirmation and invalidation rules                       |
| `src/components/**`             | Side panel UI; `ui/` = shadcn primitives copied from sakubun            |
| `test/adapter.test.ts`          | jsdom adapter tests on a synthetic mock-fap-v2 DOM                      |
| `test/gates.test.ts`            | No emoji, no submit/click in adapter, type scale, no secrets            |
| `scripts/validate-dist.mjs`     | Release gate on the built manifest and adapter                          |

## Page modes

- `fixture`: origin in `VITE_FIXTURE_ORIGINS` **and** `body[data-fap-fixture="mock-fap-v2"]`. Course
  and session ID come from table data attributes; fill and fixture save are allowed.
- `local`: `file://` page without the fixture marker (a saved lecturer HTML). Fill and verify only;
  the file on disk is never changed.
- anything else: refused before any read.
