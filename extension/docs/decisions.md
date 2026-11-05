# Decisions

Newest last. Each entry: context, decision, consequence. Supersede by adding a new entry.

## D-001 2026-10-04 Standalone project; live FAP disabled

Context: the extension lived inside the `fap-attendance-assistant` monorepo (ADR 0003, 0010, 0012)
and the product owner asked for a standalone extension system reusing what worked. FAP has no
public API and no written authorization for automation exists.

Decision: new repository, same safety boundary. Targets are the versioned synthetic fixture
(`mock-fap-v2`) and saved lecturer HTML on `file://`. `*.fpt.edu.vn` is rejected at config parse
time so a build cannot even request it.

Consequence: enabling a real origin needs a superseding entry, written authorization, a redacted
reference page turned into a synthetic fixture, and adapter tests against it.

## D-002 2026-10-04 Fill and verify only; the lecturer saves

The adapter interface has no save for FAP. It sets `input.checked` (never runs inline handlers of a
saved page), re-reads the DOM, and reports mismatches. Fixture-only "fill and save" dispatches the
fixture's own `fap-fixture-save` event and checks its receipt (assistant ADR 0012). Enforced by three
independent gates: ESLint, `test/gates.test.ts`, `scripts/validate-dist.mjs`.

## D-003 2026-10-04 Strict roster and context matching for every source

Every source (backend, file, sheet, manual) produces the same `SourceBatch` and goes through
`buildDraft`. Context fields both sides carry must match; fields a side lacks are shown as not
checked. The roster must match exactly in both directions. Files that list only absent students are
rejected on purpose: a partial file cannot be told apart from a truncated one. The template button
gives lecturers a complete file to start from.

## D-004 2026-10-04 Side panel, on-demand injection, session-only tokens

A side panel stays open while the lecturer checks the page, unlike the old 460px popup. The adapter
is injected with `chrome.scripting` only when the lecturer reads the page; there is no always-on
content script and the CRXJS `web_accessible_resources` entry is stripped. Switching or reloading the
tab invalidates the snapshot. Backend and Google tokens live in `chrome.storage.session`.

Google Sheets uses `launchWebAuthFlow` (works in Chrome and Edge) with `spreadsheets.readonly`.
`identity` and the Sheets host are requested only when `VITE_GOOGLE_CLIENT_ID` is set. The redirect
URI depends on the extension ID, so a stable `VITE_EXTENSION_PUBLIC_KEY` is needed for unpacked use.

## D-005 2026-10-04 Sakubun stack and conventions

React 19 + TypeScript, Vite 8 + CRXJS 3, Tailwind 4 with the sakubun terracotta tokens, shadcn
(`radix-nova`) primitives, lucide, sonner, zod, Vitest, ESLint flat config, Prettier (sakubun
settings), knip. No emoji (gate). Pure logic in `src/lib`, thin components. TypeScript stays on 6.0
because typescript-eslint does not yet support 7.x.

## D-006 2026-10-04 Not ported from the old extension

- `mock-fap-v1` adapter and the source-bundled demo batch: historical, replaced by real sources.
- Hard-coded API URL: now `VITE_API_BASE_URL`. (Hereby, 11/2026: Lab 1 backend dropped; the source reads Firestore via REST with `VITE_HEREBY_API_KEY`.)
- `/extension/sync-runs` reporting: present in the assistant OpenAPI but not implemented by its API;
  add when the backend ships it.

## D-007 2026-10-04 Opt-in "keep current status" for partial files and sheets

Context: lecturers often keep a list of absent students only; D-003 rejected such files.

Decision: an opt-in option (off by default) lets file and sheet sources omit students. Unlisted page
students keep their current page status, are marked "giữ nguyên" in the draft, and the load notice
turns into a warning with their count. Still fatal: codes not on the page, duplicates, unreadable
statuses, context mismatch, and a source with no student of the page. Backend approved batches stay
strict whatever the option, because they are full rosters by construction. The preference survives
source changes within the panel session; toggling it rebuilds the draft and clears the confirmation.
On re-read, kept students take the NEW page status (never an older snapshot).

Supersedes D-003 only for file and sheet sources with the option enabled.

## D-008 2026-11-05 Hereby look instead of the sakubun terracotta theme

Context: the extension ships as part of the Hereby system (app, web admin, extension) and must
look like one product. Decision: `src/styles/globals.css` carries the Hereby "Teal sâu" tokens
(shadcn-like), the same values as `design/tokens/hereby.css` generated from
`packages/core/lib/theme/tokens.dart`: background #F7FBFB, white cards with a #D8E2E2 border, no
shadow, radius 10, controls radius 6, one ink colour #141C1D for text, primary teal #00746F with
white text on main buttons and for links, icons and selection. Be Vietnam Pro is bundled from `src/assets/fonts` (woff2 converted
from the OFL TTFs in `packages/core/fonts`; no remote font). The header shows the Hereby icon with
the name "Hereby cho FAP" (logo: the letter H whose crossbar is a check mark). The dark variant is derived from the same teal until the app defines one.
When `design/tokens/hereby.css` reaches this branch, map the shadcn variables onto its `--hb-*`
variables instead of the local copy; never alias them through `--color-*` (Tailwind's theme
namespace, which would make a variable cycle). Supersedes the theme part of D-005; the stack and
conventions of D-005 stay.
