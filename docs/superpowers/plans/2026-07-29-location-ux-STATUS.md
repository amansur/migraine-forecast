# Location UX — Execution Status

**Plan:** `docs/superpowers/plans/2026-07-29-location-ux.md`
**Spec:** `docs/superpowers/specs/2026-07-29-location-ux-design.md`
**Branch:** `location-ux` (branched from `main`)
**Mode:** inline execution, incremental commits (one commit per task).

## How to resume

1. `git checkout location-ux`
2. Read the plan file above and this status.
3. Continue at the first task below whose status is not ✅. Each task is TDD
   (write failing test → run → implement → run → commit). The plan has the exact
   code and commands per step.
4. After each task: mark it ✅ here with its commit hash and update "Last updated".
5. Env note: Task 1 & 4 need `flutter pub get` / `dart run build_runner build
   --delete-conflicting-outputs` on the user's machine. Work in the MAIN repo
   checkout (not a worktree) — the user runs flutter there.

## Task status

- [ ] Task 1 — Schema v16 + columns + migration + backfill helper — ⬜ not started
- [ ] Task 2 — Thread resolved location through domain/engine/persistence — ⬜ not started
- [ ] Task 3 — Persist manual location label — ⬜ not started
- [ ] Task 4 — ReverseGeocoder service + provider (adds `geocoding` dep) — ⬜ not started
- [ ] Task 5 — Shared effective-location display provider — ⬜ not started
- [ ] Task 6 — Settings: neutral hint, prefill, show name — ⬜ not started
- [ ] Task 7 — Today: current location line — ⬜ not started
- [ ] Task 8 — History day-detail: label from stored coords — ⬜ not started

## Log

- 2026-07-29: branch created, status file initialized. Starting Task 1.

**Last updated:** 2026-07-29 (Task 1 in progress)
