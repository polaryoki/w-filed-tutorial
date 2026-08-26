# Progress

## Current status

Phases 1-8 are implemented. The current build includes run-scoped XP, physical
XP drops, scalable levels, three-choice upgrades, paused selection, and
immediate live stat application on top of the established character, weapon,
relic, Shop, and Boss boundaries.

## Tasks

- [x] Phase 1: stabilize MainMenu -> Game -> Shop -> Game.
- [x] Phase 2: character Resources, selection flow, and multi-attribute resolver.
- [x] Phase 3: independent weapon Resource, firing system, and projectile stats.
- [x] Phase 4: data-driven weapon synergies and non-recursive resolution.
- [x] Phase 5: complete Boss round spawn, combat signals, reward, timeout, and Shop transition.
- [x] Phase 6: weapon offers, weapon upgrades, rerolls, and current-run transaction boundaries.
- [x] Phase 7: balance resource validation, Boss HUD feedback, and repeatable smoke validation.
- [x] Phase 8: run-scoped XP, levels, physical XP drops, and paused three-choice upgrades.

## Commands run

- `godot --headless --path . --editor --quit`
- `godot --headless --path . --editor --check-only --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase1_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase3_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase4_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_integration_smoke.gd`
- `godot <compatible-headless-options> --script res://tests/phase8_smoke.gd`
- `godot <compatible-headless-options> --scene res://tests/phase8_integration.tscn`
- Phase 1-8 smoke and all Phase 5/8 integrations were run with isolated
  `APPDATA`, Dummy audio, headless display, `gl_compatibility`, and OpenGL 3.

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

Godot 4.7.1 still logs a Windows root-certificate-store warning. Isolated
`APPDATA` plus Dummy audio and headless OpenGL compatibility avoids the former
runtime crash and all current tests exit successfully.

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

Phase 8 is closed. Phase 9 has not been designed or started.

## Phase 7 decisions

- Balance values remain in Resource assets; HUD reads runtime Boss state only.
- No persistence, new progression systems, or scene ownership changes were added.

## Final acceptance

- Phase 1-7 smoke scripts all pass editor `--check-only` without parse or load errors.
- Phase 1-7 smoke scripts and both Phase 5 integration harnesses pass real
  runtime/headless execution when Godot uses an isolated writable `APPDATA`,
  Dummy audio, and the headless OpenGL compatibility renderer.
- The remaining root-certificate-store warning is environmental and does not
  affect the local runtime suite result.

## Phase 5 runtime regression fix

- Dynamically constructed Boss instances now listen for the Bullet collision
  layer, matching the existing Bullet/Enemy damage contract used in Game.
- Boss timeout is terminal and emits exactly once rather than once per frame.
- Runtime tests now set up Boss configuration before tree entry, wait for the
  correct physics/process frames, and observe signals through persistent test
  state. Phase 3/4 runtime smoke tests validate loaded scripts without trying
  to reload scripts that already have live instances.

## Phase 5 decisions

- Boss behavior is isolated in `Boss` and configured by `BossConfig`; ordinary
  `EnemyConfig` remains unchanged.
- Health thresholds select a single current phase without recursive effects.
- Telegraph, timeout, phase change, and one-shot defeat reward are signals so
  `Game` can own scene transitions and `GameSession` can own run rewards.
- Boss spawning is gated by `BossConfig.spawn_round`; defeat credits
  `GameSession.current_coins` before the existing Shop transition.

## Phase 8 decisions

- GameSession owns XP, thresholds, queued level-ups, offers, and chosen upgrade
  stacks; no permanent or cross-run state was introduced.
- XP uses a dedicated physical pickup while reusing the existing Pickup layer
  and Player pickup-range collision contract. Coin behavior remains unchanged.
- Upgrade Resources are immutable; character/relic stats resolve first, then
  Phase 8 stacks. Live choices update Player and WeaponSystem immediately.
- Game pauses the scene tree for choices without changing `Engine.time_scale`;
  result dialogs and scene transitions retain their existing terminal control.

## Phase 8 runtime verification

- Phase 1-8 smoke scripts passed with isolated `APPDATA`, Dummy audio, headless
  display, `gl_compatibility`, and OpenGL 3.
- `tests/phase5_integration.tscn`, `phase5_integration_smoke.gd`, and
  `tests/phase8_integration.tscn` passed under the same real runtime setup.
- The Windows root-certificate-store warning remains environmental and does
  not change test exit codes.
