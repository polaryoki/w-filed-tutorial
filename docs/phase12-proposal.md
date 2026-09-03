# Phase 12 Proposal: Run Build Stat Sheet

## Goal

Turn the existing character, relic, level-up, and weapon-level effects into one small,
deterministic build-stat pipeline suitable for a Brotato-style run: a reward changes a stat,
the final stat sheet changes, and Player/WeaponSystem visibly use the result in combat.

## Current findings

- `GameSession.resolve_character_stats()` already combines character base values, relic effects,
  and `level_upgrade_stacks`, then caches a defensive dictionary.
- Existing runtime stats include max health, move speed, damage, projectile count, pickup range,
  luck, armor, invincibility duration, and bullet spawn distance. Attack interval is represented
  as a multiplier; projectile speed/range/crit are currently weapon/config concerns or absent.
- `Player` copies resolved values and updates pickup radius, movement, shooting interval, and
  WeaponSystem modifiers. Temporary pickup buffs are separate and time-limited.
- `WeaponSystem` resolves per-weapon level stats and applies character damage, fire-interval,
  projectile-count, and synergy modifiers before firing.
- Relic and Upgrade resources are immutable definitions; GameSession owns acquired IDs/stacks.

## Non-goals

No permanent progression, generic inventory/ECS, event bus, enemy expansion, final boss, or large
visual rewrite. Task 6 Shop remains snapshot-driven and all purchases remain GameSession APIs.

## Success criteria

At least one level-up and one Shop relic can be applied in a run; a defensive Final Stat Sheet
reports the combined result; Player and WeaponSystem consume it; an integration smoke proves a
changed damage/interval/projectile or survival value in a real runtime path.

## Open decisions for implementation

Use a compact typed modifier record with `stat_id`, `operation`, `value`, and `source_id`.
Start with flat and percent operations only where existing values justify them; keep the public
stat set small and add fields incrementally with focused tests.
