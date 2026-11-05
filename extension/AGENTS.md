# fap-attendance-extension — agent rules

Standalone Chrome/Edge Manifest V3 side-panel extension that helps a lecturer fill attendance on a
recognized FAP-style page. Derived from `fap-attendance-assistant` (its `apps/browser_extension`
v0.4.0 and `apps/fap_fixture`), rebuilt on the sakubun stack. **Read `docs/00-map.md` first**; the
_why_ and the traps live in `docs/decisions.md`.

## Invariants (do not break; each is gate-enforced where noted)

1. **Never save live FAP.** The page adapter may only read, set radio `checked`, verify, and (fixture
   only) dispatch the fixture's own `fap-fixture-save` event. No `click()`, `submit()`,
   `requestSubmit`, `__doPostBack`, network call or synthetic mouse event in the adapter. Enforced by
   `test/gates.test.ts`, ESLint `no-restricted-properties` and `scripts/validate-dist.mjs`. (D-002)
2. **Live FAP origins stay disabled.** `src/lib/env-config.ts` rejects `*.fpt.edu.vn`; the manifest
   only lists configured fixture origins and `file:///*`. Enabling a real origin needs a new decision
   in `docs/decisions.md`, written authorization and a verified adapter. (D-001)
3. **Fail closed.** Unknown layout, context drift, roster mismatch, duplicate or unreadable status
   stops the flow with a Vietnamese message. Nothing is defaulted or guessed. (D-003)
4. **Exactly `ATTEND` / `ABSENT`.** No LATE, no third state.
5. **Least privilege.** Every permission is tied to a configured feature (`manifest.config.ts`). No
   cookies, webRequest, `<all_urls>`, externally_connectable, always-on content scripts or
   web_accessible_resources. Tokens live only in `chrome.storage.session`. (D-004)
6. **No emoji** in UI, copy, code or comments. Use lucide icons or words. Enforced by
   `test/gates.test.ts`. (D-005)
7. UI copy = Vietnamese; code, comments, internal docs = English. README is the Vietnamese user guide.
8. Type scale: body `text-sm` (set on `body`), meta `text-xs`, headings `text-base`. No arbitrary
   `text-[..]` outside `src/components/ui/**`. Single-line text that can overflow uses `truncate`
   inside a `min-w-0` parent.
9. Synthetic data only in source, tests and screenshots (`SE18xxxx`, `Demo Student NN`). Never commit
   a real FAP HTML, student names, tokens, OAuth client secrets or `.pem` keys.

## Working here

- Node >= 22. `npm install`, then `npm run check` (typecheck, lint, prettier, vitest, build, dist gate).
- `npm run dev` for HMR (load `dist/` unpacked once), `npm run package` for the store ZIP.
- Pure logic lives in `src/lib/*` and `src/sidepanel/workflow.ts` and is unit-tested; React components
  stay thin. New behavior ships with its test (success, error and boundary case).
- The adapter is the risky surface: any change there needs a matching case in `test/adapter.test.ts`.
- Record user-visible changes in `CHANGELOG.md`; architectural choices go to `docs/decisions.md`.
