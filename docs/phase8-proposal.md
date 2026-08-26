# Phase 8 Proposal: In-run Experience and Level-up Choices

## Goal

Add a run-scoped combat growth loop: enemies drop experience entities, pickups
grant XP, thresholds queue level-ups, and Game pauses combat while the player
chooses one of three distinct data-driven upgrades. The selected upgrade takes
effect immediately and remains active across rounds in the current run.

## Functional requirements

- `EnemyConfig` defines a positive experience reward independently of coins.
- Enemy death always spawns one XP pickup carrying the configured reward.
- `GameSession` owns `current_level`, `current_xp`, `xp_to_next_level`, pending
  level-up choices, and chosen upgrade stacks.
- XP overflow is retained and one grant may queue multiple level-ups.
- Each pending level-up presents three distinct options from a Resource-driven
  pool of at least six upgrades.
- Upgrade selection pauses the scene tree, applies exactly one option, and
  resumes only after all queued level-ups are resolved.
- HUD displays level and XP progress.
- Run reset restores level 1, zero XP, the first threshold, no pending choices,
  and no chosen upgrades.

## Compatibility and non-goals

- Character and relic resolution remains the base-stat source; Phase 8 bonuses
  are applied afterward and never mutate Resource assets.
- Weapon projectile construction remains in `WeaponSystem`; Phase 8 damage is
  passed as a runtime resolved value.
- Existing Coin, Pickup, Shop, Boss, result dialog, and round transitions keep
  their ownership and behavior.
- No permanent saves, Phase 9, networking, achievements, meta progression, or
  large UI/art redesign.

## Success criteria

Runtime/headless tests cover XP grants, overflow, multi-level grants, reset,
three distinct offers, real stat changes, XP entity collision, pause, resume,
and queued level-up resolution. Phase 1-7 runtime tests and Phase 5 integration
tests remain green.

## Assumptions

- The requested `Luck +5` means five percentage points (`0.05`) because current
  character luck is normalized to `[0, 1]`.
- The existing Player pickup-range Area2D is the first-version proximity pickup
  mechanism; animated attraction is not required for Phase 8 acceptance.

