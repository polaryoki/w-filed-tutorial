# Progress

## Current status

Phase 1 current-run flow is implemented. Its editor smoke command passes after
the test defers work until the startup frame and initializes the autoload test
context. Phase 2 character data, selection, and per-round stat resolution are
implemented and covered by `tests/phase2_smoke.gd`.

## Tasks

- [x] Phase 1: stabilize MainMenu -> Game -> Shop -> Game.
- [x] Phase 2: character Resources, selection flow, and multi-attribute resolver.
- [x] Phase 3: independent weapon Resource, firing system, and projectile stats.

## Commands run

- `godot --headless --path . --editor --quit`
- `godot --headless --path . --editor --check-only --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase1_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase3_smoke.gd`

## Phase 2 decisions

- `GameSession` owns selected-character identity and cached resolution state.
- Base values are resolved before relic bonuses; additive effects and
  multiplicative effects use separate, deterministic passes.
- Resolved results are clamped and continuous values are rounded to three
  decimals; integer values are rounded to the nearest integer.
- Damage, projectile count, starting weapon, and passive are data contracts for
  Phase 3. Existing Player shooting behavior is intentionally unchanged.
- Pickup range uses a dedicated Area2D so the existing Player body collision
  shape and direct-contact collection remain compatible.

## Known environment risk

The installed Godot 4.7.1 Windows build crashes in this workspace when running
custom SceneTree smoke scripts without `--editor`. The requested editor smoke
command and editor import/check complete with exit code 0; the crash is an
engine/environment issue rather than a Phase 2 assertion failure.

## Phase 3 decisions

- `WeaponConfig` owns projectile combat parameters; `WeaponSystem` owns bullet
  construction and spread; Player remains input and movement orchestration.
- Bullet range and piercing are resolved per projectile and do not mutate
  character stats.

## Next step

Design and implement the independent weapon Resource/system in Phase 3 without
moving weapon behavior into the character resolver.
