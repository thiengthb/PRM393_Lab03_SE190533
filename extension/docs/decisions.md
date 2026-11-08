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
- Hard-coded API URL: now `VITE_API_BASE_URL`. (Attendo, 11/2026: Lab 1 backend dropped; the source reads Firestore via REST with `VITE_HEREBY_API_KEY`.)
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

## D-008 2026-11-05 Attendo look instead of the sakubun terracotta theme

Context: the extension ships as part of the Attendo system (app, web admin, extension) and must
look like one product. Decision: `src/styles/globals.css` carries the Attendo "Xanh xô thơm" tokens (sage, palette C)
(shadcn-like), the same values as `design/tokens/hereby.css` generated from
`packages/core/lib/theme/tokens.dart`: background #FBFAF8, white cards with a #E1E0DA border, no
shadow, radius 10, controls radius 6, one ink colour #1C1B16 for text, amber #8D5E00 for warnings, primary sage #386F5F with
white text on main buttons and for links, icons and selection. Be Vietnam Pro is bundled from `src/assets/fonts` (woff2 converted
from the OFL TTFs in `packages/core/fonts`; no remote font). The header shows the Attendo icon with
the name "Attendo cho FAP" (logo: a dot inside a four-corner viewfinder). The dark variant is derived from the same sage until the app defines one.
When `design/tokens/hereby.css` reaches this branch, map the shadcn variables onto its `--hb-*`
variables instead of the local copy; never alias them through `--color-*` (Tailwind's theme
namespace, which would make a variable cycle). Supersedes the theme part of D-005; the stack and
conventions of D-005 stay.

## D-009 2026-11-06 Attendo brand: Xanh ngọc, Onest, wordmark

Context: the app was renamed Attendo and restyled on thienui (UI-TASTE.md): Slate Teal "Xanh ngọc",
cool neutrals, a real dark theme, Onest, radius 8, flat cards and buttons with a 2px solid bottom
edge. Decision: `src/styles/globals.css` copies those values from `packages/core/lib/theme/tokens.dart`
(AppNeutral.cool*, AppTones, AppPalette.teal) for `:root` and `.dark`. Main buttons are solid teal
#308E84 with ink text (#131519) and a #0B6961 edge (`--primary-edge`); pressing moves the button down
2px and drops the edge. Teal for text and icons is `--primary-ink` #04756B. Onest replaces Be Vietnam
Pro in `src/assets/fonts` (woff2 from the OFL TTFs in `packages/core/fonts`). The header shows the
`BrandWordmark` ("attend" + a ring with a centre dot as the o, same geometry as the app) and "cho FAP";
toolbar icons come from `tool/brand/gen_icons.py`. Supersedes the colours, font, radius and logo of
D-008; its rule about never aliasing through `--color-*` stays.

## D-010 2026-11-08 Emulator-only test build for the Attendo source

Context: the demo needs an automated check of the whole chain (Attendo app closes a slot, the panel
reads it, fills the mock FAP page), and that check runs on Firebase Emulator, not on the real
project. Decision: `VITE_HEREBY_EMULATOR_HOST` (only `localhost` or `127.0.0.1`) points Auth and
Firestore REST at the emulator (`http://<host>:9099`, `http://<host>:8080`) and replaces the three
googleapis host permissions with those two local origins. Release builds leave it empty, so their
manifest is unchanged (D-004). Used by `e2e_web/test_extension.py` only.
