# Changelog

## [Unreleased]

### Changed

- Rebranded to Attendo (D-009): thienui "Xanh ngọc" (slate teal) colours from the Attendo app in light
  and dark, Onest bundled locally, radius 8, buttons with a 2px solid edge that sinks on press, the
  "attendo" wordmark plus "cho FAP" in the header, new manifest and toolbar icons.
- The panel is now three numbered step cards (Đọc trang, Chọn nguồn dữ liệu, Kiểm tra bản nháp);
  steps that cannot start yet are shown greyed out. Most helper text was shortened.
- Action bar: "Điền vào trang" and "Kiểm tra" share one row.

### Fixed

- Toasts sit below the header instead of covering the wordmark for a few seconds (LOI-07).
- Tabs and checkboxes now show their active/checked state: the shadcn classes used `data-active`,
  `data-checked` and `data-horizontal`, which Radix never sets (it sets `data-state` and
  `data-orientation`), so the source tabs also stacked beside their content.

### Added

- `VITE_ATTENDO_EMULATOR_HOST` for a test build that reads Firebase Emulator instead of the real
  project (D-010); release builds are unchanged.

- Opt-in "Sinh viên không có trong nguồn: giữ trạng thái hiện tại" for file and Google Sheets
  sources, so a list of only absent (or only present) students can be imported. Off by default;
  unlisted students are marked "giữ nguyên"; backend approved batches stay strict.

## [1.0.0] - 2026-10-04

First release as a standalone project, derived from `fap-attendance-assistant` extension 0.4.0 Beta.

### Added

- Side panel (stays open while checking the page) replacing the fixed 460px popup.
- Four data sources feeding one draft: backend approved batch, CSV/TSV/XLSX file, read-only Google
  Sheets, and manual editing from the page's current statuses.
- Importer that understands the assistant's exported review tab (header on row 8, `FINAL_STATUS`,
  `LỚP/MÔN/NGÀY/SLOT` context) and plain CSVs with Vietnamese headers and statuses.
- "Tải tệp mẫu từ trang": a CSV template generated from the open page, safe against formula injection.
- Bulk "all present / all absent", also applied only to search results when filtering.
- Snapshot invalidation on tab switch or reload.
- Gates: no emoji, no submit/click in the adapter, type scale, no secrets, built-manifest validation.

### Changed

- Rebuilt on React 19, TypeScript, Vite 8 + CRXJS, Tailwind 4 and shadcn with the sakubun theme
  (light and dark follow the system).
- Configuration (API, fixture origins, Google client, extension key) moved to `VITE_*` env; the
  manifest requests only what is configured.
- The page adapter is injected on demand as an IIFE; no always-on content script and no
  web-accessible resources.

### Removed

- `mock-fap-v1` adapter and the source-bundled demo batch.
