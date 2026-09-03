# Phase 12 Design: Final Stat Sheet and Modifiers

## Data flow

```text
Character Resource base stats
  -> GameSession-owned Run modifiers (Relic + Upgrade)
  -> deterministic Final Stat Sheet snapshot
  -> Player runtime fields + WeaponSystem per-entry stats
  -> actual movement, firing, projectile and survival behavior
```

## Ownership

GameSession remains authoritative for selected character, owned relic IDs, upgrade stacks, weapon
levels, and derived build snapshots. Player owns only applied runtime copies and temporary pickup
state. WeaponSystem owns per-weapon resolved runtime entries. Shop only displays snapshots and
forwards existing commands.

## Initial stat set

Implement the smallest useful subset first: `damage`, `attack_speed`, `projectile_count`,
`projectile_speed`, `range`, `max_health`, `armor`, `move_speed`, `pickup_range`, `luck`, and
`xp_gain`. `crit_chance`/`crit_damage` may remain deferred until the combat hit contract supports
them. Existing `fire_interval` and `bullet_spawn_distance` remain compatibility aliases where
needed.

## Modifier record and stacking

Each modifier is a primitive dictionary `{stat_id, operation, value, source_id}`. `operation` is
`flat` or `percent`; percent values use decimal factors (0.25 = +25%). Sources are tagged
`character`, `relic`, `upgrade`, or `synergy` for diagnostics only.

For each stat: start from character/weapon base; apply all flat modifiers in stable source order;
apply percent modifiers multiplicatively in stable source order; clamp to the stat bounds. No
unbounded growth: damage/max health/projectile speed/range use sensible upper bounds, counts and
chance use explicit caps, and movement/interval use positive lower bounds. Relic and Upgrade have
no implicit priority: both contribute to the same ordered pipeline, while weapon-specific values
are resolved per WeaponSystem entry and player-global values are resolved once.

## Compatibility

Existing `resolve_character_stats()`, `get_weapon_upgrade_levels()`, Shop snapshots, purchase,
lock, reroll, reload, Continue, and Phase 10 WeaponSystem APIs remain valid. New stat-sheet APIs
must return defensive copies and must not mutate Resources.

## Verification

Focused tests assert deterministic stacking, negative modifiers, caps, cache invalidation, and
immutability. Integration tests apply XP/Upgrade and Shop Relic actions, then inspect Player and
WeaponSystem runtime values and fire one real projectile path.
