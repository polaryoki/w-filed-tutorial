# Phase 9 Proposal: Data-driven Wave Director

## Goal

Turn the existing timed combat round into a configurable wave runtime while
preserving the established Game -> Shop -> Game loop, Phase 8 level-ups, Boss
ownership, and current-run GameSession state.

## Functional requirements

- Define a `WaveConfig` Resource containing wave ID/number, duration, spawn
  budget, spawn interval, simultaneous enemy cap, weighted enemy entries,
  optional completion coins, and optional Boss configuration reference/rule.
- Add a focused `WaveDirector` that tracks time, remaining budget, spawned and
  defeated counts, and completion readiness. It must not own UI or scene
  transitions.
- `Game` supplies spawn points and creates enemies selected by the director.
- An ordinary wave completes immediately when its configured duration expires;
  surviving enemies do not need to be cleared and cannot delay transition.
- Level-up pause freezes wave time, enemy processing, and spawn timers without
  consuming budget. Selection resumes the same wave.
- Result dialogs, player death, Boss defeat/timeout, and Shop transition remain
  mutually exclusive terminal paths.
- HUD shows wave number, remaining time, and defeated/target progress where a
  finite target exists.

## Non-goals

- No multi-weapon runtime, Shop rewrite, new item ecosystem, permanent save,
  meta progression, Phase 10 work, or finished art pass.
- No new enemy behavior is required beyond data-driven composition of existing
  enemies.

## Acceptance checks

1. At least three `WaveConfig` Resources load and have distinct pacing.
2. Spawn budget cannot go negative and simultaneous cap is respected.
3. Pausing for a Phase 8 level-up does not advance wave time or spawn enemies.
4. Resuming continues the same wave state.
5. Wave completion transitions once to Shop; player death never enters Shop.
6. Boss spawn/defeat/timeout behavior remains compatible.
7. Phase 1-9 runtime smoke and all integration tests pass under the compatible
   headless environment.

## Approved Phase 9 decisions

- Keep `GameSession.current_round` as the public wave number to avoid a risky
  migration; UI may label it as Wave.
- Ordinary waves end immediately when duration reaches zero. The scene change
  removes survivors after Game commits state exactly once.
- `WaveConfig.completion_coins` is an explicit non-negative reward. Game credits
  it atomically to current-run GameSession coins before entering Shop. Enemy
  coin drops remain independent.
