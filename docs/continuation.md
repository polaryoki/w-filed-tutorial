# Development Continuation Handoff

## Where the project is now

Phases 1-9 are complete and runtime-verified. The current playable loop has
character selection, timed combat rounds, enemy drops, coins, relics, weapons,
synergies, Boss flow, Shop transactions, XP levels, and paused three-choice
upgrades. All progression is current-run only.

Phase 9 is complete. The next approved target is Phase 10, which must begin
with a separate planning/design pass before implementation.

## Start here next session

Read, in order:

1. `docs/continuation.md`
2. `docs/tasks/progress.md`
3. `docs/development-roadmap.md`
4. `docs/visual-direction.md`
5. `docs/phase9-proposal.md`
6. `docs/phase9-design.md`
7. `docs/tasks/phase9-wave-director.md`
8. `docs/phase9-prompt.md`
9. `docs/architecture.md`, `docs/game-mechanics.md`, and current related code

Then inspect `git status` before editing. Existing user changes must be
preserved. Re-audit actual Game/GameSession/Enemy/Boss/Shop/Phase 8 behavior;
the design draft is guidance, not authority over current code.

## Immediate next action

Phase 9 is closed. Do not implement Phase 10 until its proposal, design, task
breakdown, and acceptance checks are explicitly prepared and approved.

## Runtime verification environment

Use a fresh writable isolated APPDATA directory and run Godot with:

```powershell
$phaseTestAppData = Join-Path $env:TEMP "godot-w-filed-tests"
New-Item -ItemType Directory -Force $phaseTestAppData | Out-Null
$env:APPDATA = $phaseTestAppData

godot `
  --headless `
  --display-driver headless `
  --audio-driver Dummy `
  --rendering-method gl_compatibility `
  --rendering-driver opengl3 `
  --path . `
  --script res://tests/phase8_smoke.gd
```

Scene-backed integration tests use `--scene` instead of `--script`. Godot may
log a Windows root-certificate-store warning; current tests still exit zero.

## Guardrails

- Follow vibe-coding-workflow: requirements/design/tasks before implementation.
- Do not implement Phase 10 while Phase 9 is active.
- Do not add permanent saves, meta progression, networking, achievements, ads,
  purchases, or external services without explicit approval.
- Preserve GameSession run-state ownership, Game orchestration, Player input,
  WeaponSystem firing, Enemy/Boss behavior, and Shop transaction boundaries.
- Keep third-party inspiration abstract. Do not copy commercial characters,
  factions, terms, art, UI, icons, sound, or balance data.
- Run real runtime/headless tests, not only editor `--check-only`.

## Last verified baseline

- Phase 1-8 smoke: passed.
- Phase 5 integration scene and smoke: passed.
- Phase 8 integration scene: passed.
- Compatible environment: isolated APPDATA, Dummy audio, headless OpenGL.
