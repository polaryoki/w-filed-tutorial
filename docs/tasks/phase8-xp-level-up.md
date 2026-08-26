# Phase 8 Task: XP and Level-up Loop

## Objective

Implement the Phase 8 proposal and design without changing the existing round,
Boss, Shop, Coin, relic, or permanent-state boundaries.

## Input docs

- `docs/phase8-proposal.md`
- `docs/phase8-design.md`
- `docs/architecture.md`
- `docs/game-mechanics.md`
- `docs/implemented-features.md`

## Expected files

- `resourse/progression/upgrade_config.gd` and six upgrade Resources
- `resourse/config/enemy_config.gd` and enemy Resource values
- `scene/experience_pickup.gd`, `scene/experience_pickup.tscn`
- `scene/game_session.gd`, `scene/enemy.gd`, `scene/player.gd`
- `scene/weapon_system.gd`, `scene/game.gd`, `scene/game.tscn`
- `tests/phase8_smoke.gd`, `tests/phase8_integration.gd/.tscn`
- Phase 8 and shared project documentation

## Implementation steps

1. Add upgrade Resources and GameSession XP/threshold/pending/upgrade state.
2. Add configured XP rewards and idempotent XP pickup spawning/collection.
3. Apply chosen upgrade effects to live Player/WeaponSystem and future rounds.
4. Add level/XP HUD and paused three-card selection flow in Game.
5. Run Phase 8 focused runtime tests, Phase 1-8 smoke, and all integrations.
6. Inspect diff and update progress with exact runtime results.

## Definition of done

- All Phase 8 success criteria pass under the isolated runtime/headless setup.
- Three offers are distinct and one choice is consumed per queued level.
- Result, Boss, Shop, Coin, character, weapon, and relic behavior regressions
  are absent from the existing suite.
- No permanent state or Phase 9 functionality is added.

## Dependencies

Phases 1-7 and the compatible runtime/headless command are prerequisites.

