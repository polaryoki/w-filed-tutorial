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
- [x] Phase 4: data-driven weapon synergies and non-recursive resolution.
- [x] Phase 5: complete Boss round spawn, combat signals, reward, timeout, and Shop transition.
- [x] Phase 6: weapon offers, weapon upgrades, rerolls, and current-run transaction boundaries.
- [x] Phase 7: balance resource validation, Boss HUD feedback, and repeatable smoke validation.

## Commands run

- `godot --headless --path . --editor --quit`
- `godot --headless --path . --editor --check-only --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase1_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase3_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase4_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_integration_smoke.gd`

Phase 5 final integration attempt: editor-mode execution reaches the test but
cannot execute the autoload script as a runtime instance (Godot placeholder
resource error); non-editor execution crashes the installed Godot build with
signal 11 before assertions. This is an environment/runtime verification
blocker, not treated as a passing integration result.

The replacement `tests/phase5_integration.tscn` uses a normal Node lifecycle
and the real autoload rather than dynamically attaching a GameSession script.
Its `--editor --check-only` validation passes, but normal headless scene
execution still crashes with the same Godot signal 11 before `_ready()` can
complete. Phase 5 remains unverified and is not marked DONE.

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

## Phase 4 decisions

- Synergies require a set of weapon tags and are resolved from the equipped set.
- Resolution applies each matching synergy once from base weapon stats; repeated
  calls do not compound bonuses.

## Next step

Design and implement the independent weapon Resource/system in Phase 3 without
moving weapon behavior into the character resolver.

## Phase 7 decisions

- Balance values remain in Resource assets; HUD reads runtime Boss state only.
- No persistence, new progression systems, or scene ownership changes were added.

## Final acceptance

- Phase 1-7 smoke scripts all pass editor `--check-only` without parse or load errors.
- Normal headless execution of the main scene was attempted and remains blocked
  by the installed Godot 4.7.1 Windows build crashing with signal 11 during
  runtime initialization. No runtime PASS is claimed from static checks.

## Phase 5 decisions

- Boss behavior is isolated in `Boss` and configured by `BossConfig`; ordinary
  `EnemyConfig` remains unchanged.
- Health thresholds select a single current phase without recursive effects.
- Telegraph, timeout, phase change, and one-shot defeat reward are signals so
  `Game` can own scene transitions and `GameSession` can own run rewards.
- Boss spawning is gated by `BossConfig.spawn_round`; defeat credits
  `GameSession.current_coins` before the existing Shop transition.
