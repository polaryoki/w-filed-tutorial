# Phase 2 Design

## Data flow

`MainMenu` resets the run and opens `CharacterSelect`. The selection scene
validates a `CharacterConfig.id` through `GameSession.select_character()` and
then opens `Game`. At the beginning of every `Game` scene, `GameSession`
resolves the selected character's base stats plus owned relic effects and
returns a copy of the resolved dictionary to `Player`.

```text
CharacterConfig Resources -> CharacterSelect -> GameSession.selected_character_id
                                      owned relics -> resolve_character_stats()
                                                        -> Player.apply_character_stats()
                                                        -> HUD character label
```

## Resolution contract

The result contains the character fields plus the existing round-adjustable
Player fields (`invincibility_duration`, `bullet_spawn_distance`) and an
integer `starting_coins` bonus. The resolver is cached by `current_round` and
invalidated when the selected character or owned relics change.

Order and bounds:

1. Copy base values from the selected `CharacterConfig`.
2. Apply additive bonuses (`max_health`, `armor`, `starting_coins`,
   `invincibility_duration`, `bullet_spawn_distance`).
3. Apply multiplicative bonuses (`move_speed`, `fire_interval`) to the base
   value, not to a previous resolved result.
4. Clamp health/damage/projectiles/armor to non-negative integer ranges;
   clamp speed and pickup range to positive values; clamp luck and critical
   chance to `[0, 1]`; clamp fire interval to `[0.01, 10]` seconds.
5. Round integer fields to the nearest integer and continuous fields to three
   decimal places for stable HUD/test values.

Only the existing relic effects are wired into this resolver. `damage`,
`projectile_count`, `pickup_range`, `luck`, `armor`, and `critical_chance` are
still data and resolved-stat fields; weapon damage/projectile behavior remains
owned by the future Phase 3 weapon system.

## Runtime integration

- `Player.apply_character_stats()` assigns the resolved supported fields and
  updates its pickup-range Area2D shape. It does not replace input or bullet
  orchestration.
- `Game` calls the resolver before applying relic values and grants the
  per-round `starting_coins` result once to the new Player instance.
- `Pickup` and `Coin` accept both the existing Player body contact and the
  Player pickup-range Area2D, preserving old contact behavior.
- `CharacterSelect` is a small independent scene with three option cards and a
  confirm button; no character state is stored in the scene itself.

## Risks and alternatives

- A typed `CharacterConfig` preload in an early custom `SceneTree` can be
  unavailable during editor startup. The smoke scripts therefore load the
  autoload script/resource after a deferred frame and fail explicitly if it is
  unavailable.
- A future weapon system may reinterpret damage/projectile fields. Keeping
  them in the Resource and resolver now avoids hard-coding weapon behavior into
  Player while preserving a stable data contract.
