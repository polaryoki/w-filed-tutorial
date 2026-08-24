# Phase 2 Proposal: Character Data and Attributes

## Goal

Introduce a data-driven character layer without changing the existing movement,
bullet lifetime, enemy collision, or Game -> Shop round flow. A run chooses one
of three character Resources, and each new round resolves that character's base
attributes plus the run's owned relic bonuses exactly once.

## Non-goals

- No independent weapon system or weapon upgrades (Phase 3).
- No permanent saves or meta progression.
- No recursive or cross-round mutation of already-resolved attributes.
- No changes to `project.godot` or the existing enemy/pickup resource format.

## Required outcomes

- A `CharacterConfig` Resource defines identity, presentation, base health,
  move speed, fire interval, damage, projectile count, pickup range, luck,
  armor, critical chance, starting weapon, and passive.
- At least three distinguishable character Resources are selectable before the
  first `Game` scene.
- `GameSession` owns the selected character and cached per-round resolution.
- The resolver applies base values first, then relic bonuses in a fixed order,
  with explicit clamps and rounding.
- The existing Player receives resolved values at round start and keeps its
  current movement/shooting orchestration.
- Focused smoke tests cover resources, selection, resolution idempotence,
  cross-round recalculation, and scene loading.

## Acceptance checks

1. The Phase 2 smoke command exits 0 and prints a pass marker only when all
   checks succeed.
2. Loading the character-select and game scenes produces no script compile
   errors after the test initializes the `GameSession` autoload context.
3. Resolving twice in one round does not compound relic bonuses; advancing the
   round recomputes from character base values instead of the previous result.
4. Selecting an unknown character is rejected and leaves the previous choice
   unchanged.
