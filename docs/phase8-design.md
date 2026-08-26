# Phase 8 Design

## Ownership and data flow

```text
EnemyConfig.experience_reward
  -> Enemy death -> ExperiencePickup -> GameSession.add_experience()
  -> experience_changed / level_up_queued signals
  -> Game HUD and paused LevelUpPanel
  -> three distinct UpgradeConfig Resources
  -> GameSession.apply_level_upgrade()
  -> Player.apply_level_upgrade()
  -> resume, or present the next queued choice
```

`GameSession` owns run state and threshold calculation. `Game` owns presentation
and pause arbitration. `Player` owns live movement, health, fire interval,
pickup range, and luck. `WeaponSystem` owns the resolved projectile damage used
when firing. Resources remain immutable.

## Experience and thresholds

The initial threshold is 5 XP. The threshold for the next level is computed as
`5 + (level - 1) * 3`, centralized in `GameSession`. `add_experience(amount)`
rejects non-positive input, then loops while XP meets the threshold: subtract
the threshold, increment level, increment pending choices, and calculate the
next threshold. Overflow is never discarded.

Signals publish the final XP state and number of newly queued levels. Tests may
call this pure run-state boundary without constructing Player or Game.

## Upgrade resources and stacking

`UpgradeConfig` contains identity, display text, effect type, and amount. The
first pool contains max health, movement speed, damage, attack speed, pickup
range, and luck. IDs make offers unique. `GameSession` records stack counts and
applies their deterministic effects after character and relic resolution:

- max health: `+1` per stack;
- movement speed: multiplicative `1.10` per stack;
- damage: `+1` per stack;
- attack speed: fire interval multiplicative `1 / 1.10` per stack;
- pickup range: multiplicative `1.15` per stack;
- luck: additive `0.05` per stack, clamped to 1.

Live selection calls `Player.apply_level_upgrade()` so current gameplay changes
immediately without resetting health or reapplying starting coins. New rounds
receive the same bonuses through `resolve_character_stats()`.

## Pause and UI arbitration

The LevelUpPanel uses `PROCESS_MODE_WHEN_PAUSED`. `Game` pauses only when it is
not already showing a result or transitioning. Selecting an option consumes one
pending choice. If more remain, Game generates a fresh distinct set and stays
paused; otherwise it hides the panel and unpauses.

The result dialog remains authoritative: result/transition paths clear the
level-up UI before using the existing world-stop logic. Phase 8 does not change
`Engine.time_scale`; existing result code may still set it to zero.

## XP pickup

`ExperiencePickup` mirrors Coin's collision contract on Pickup layer 32 and
accepts Player body contact or the Player pickup-range Area2D. Collection is
idempotent and calls only `GameSession.add_experience(value)`. Coin behavior is
untouched.

## Risks and alternatives

- Applying all resolved stats after every choice would refill/reset Player
  health through the existing character setup path. A focused live-upgrade
  method avoids that side effect.
- Random offer tests must not depend on a seed; uniqueness and membership are
  asserted instead of exact order.
- Pause-based integration requires the harness UI/test node to process while
  paused and to restore pause state before exit.

