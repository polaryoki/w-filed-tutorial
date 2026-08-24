# Task: Phase 2 Character Data and Attributes

## Objective

Implement the Phase 2 proposal and design while preserving the existing round,
movement, pickup, bullet, and relic behavior.

## Input docs

- `docs/phase2-proposal.md`
- `docs/phase2-design.md`
- `docs/architecture.md`
- `docs/game-mechanics.md`
- `docs/implemented-features.md`

## Files expected to change

- `resourse/character/character_config.gd` and three `.tres` instances
- `scene/game_session.gd`, `scene/player.gd`, `scene/game.gd`
- `scene/main_menu.gd`, `scene/main_menu.tscn`
- `scene/character_select.gd`, `scene/character_select.tscn`
- `scene/pickup.gd`, `scene/coin.gd`, `scene/player.tscn`
- `tests/phase2_smoke.gd`
- Phase 2 project documentation and `docs/tasks/progress.md`

## Implementation steps

1. Add the Resource schema and three balanced, fast, and durable character
   definitions.
2. Add validated selection and per-round cached resolution to GameSession.
3. Add the selection scene and route MainMenu through it.
4. Apply supported resolved fields in Player/Game and update pickup range/HUD.
5. Add focused smoke checks for data, selection, resolution, idempotence, and
   required scenes.
6. Run the editor smoke command, inspect the diff, and record results.

## Definition of done

- All acceptance checks in `docs/phase2-proposal.md` pass.
- No Phase 3 weapon behavior is introduced.
- The Phase 2 smoke test exits non-zero on any failed assertion.
- No temporary debug files or generated editor settings are included.

## Dependencies

Phase 1's current-run ownership and `GameSession` autoload are prerequisites.
