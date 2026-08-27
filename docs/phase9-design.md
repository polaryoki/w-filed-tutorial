# Phase 9 Design Draft

## Proposed modules

### WaveConfig

Immutable Resource data under `resourse/wave/`. Weighted entries should refer
to existing `EnemyConfig` Resources, not duplicate enemy stats. Validate all
durations, weights, budgets, and caps when the director is configured.

### WaveDirector

A small Node or RefCounted runtime under `scene/` with signals such as:

- `spawn_requested(enemy_config)`
- `progress_changed(snapshot)`
- `wave_completed(snapshot)`

It owns pacing state but receives authoritative enemy-created/enemy-defeated
notifications from Game. It does not instantiate scenes, credit coins, pause
the tree, show UI, or change scenes.

For ordinary waves, duration is authoritative: reaching zero requests a single
completion regardless of surviving enemies. Kill/spawn counts remain progress
and balancing telemetry, not a completion gate. Boss rounds retain their
dedicated terminal rule.

### Game integration

Game remains the orchestrator:

```text
GameSession.current_round -> WaveConfig selection -> WaveDirector
Game spawn points <-------- spawn_requested ---------|
Enemy lifecycle ----------> director notification    |
HUD <---------------------- progress snapshot        |
Shop transition <---------- completion via Game -----|
```

The existing enemy container and Player target injection remain unchanged.
Phase 8 continues to pause the SceneTree; therefore a director using normal
process mode naturally freezes. Tests must assert this rather than introducing
parallel pause flags prematurely.

## State boundaries

- `GameSession`: current wave number and run rewards only.
- `WaveConfig`: immutable pacing/content data.
- `WaveDirector`: current combat-wave runtime state.
- `Game`: Node ownership, spawn locations, HUD, terminal transitions.
- `Enemy`: its own combat/death/drop behavior.
- `Shop`: between-wave transactions only.

`current_round` remains the stored field for compatibility and is presented as
the wave number. On ordinary completion, Game applies the Resource-defined
completion coin reward once before the existing Shop transition.

## Risks

- Existing Game mixes countdown, spawn formula, Boss gating, and result checks;
  extraction must be incremental to avoid changing all terminal behavior at
  once.
- Enemy death currently has no explicit defeat signal for wave accounting.
  Phase 9 may add a one-shot signal, but must preserve drops and animations.
- Boss rounds use a special completion rule. Prefer an explicit config branch
  over forcing Boss into ordinary enemy budgets.
- Resource path spelling remains `resourse/` for compatibility; renaming the
  directory is outside Phase 9.

## Verification strategy

- Pure director smoke: budgets, weighted selection validity, caps, progress,
  completion idempotence.
- Scene integration: Game with deterministic WaveConfig, enemy creation/death,
  pause/resume, Shop transition interception, and GameSession reward.
- Regression: Phase 1-8 smoke, Phase 5 integration harnesses, Phase 8
  integration, then Phase 9 integration in the same compatible environment.
