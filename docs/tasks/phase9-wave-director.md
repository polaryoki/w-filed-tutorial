# Phase 9 Task: Wave Director and Run Pacing

## Objective

Implement `docs/phase9-proposal.md` and `docs/phase9-design.md` as the next
bounded development phase. Do not begin Phase 10.

## Required context

- `docs/continuation.md`
- `docs/development-roadmap.md`
- `docs/phase9-proposal.md`
- `docs/phase9-design.md`
- `docs/architecture.md`
- `docs/game-mechanics.md`
- `docs/tasks/progress.md`
- Current `Game`, `GameSession`, `Enemy`, `Boss`, Shop, and Phase 8 code/tests

## Expected files

- `resourse/wave/wave_config.gd` and initial `.tres` wave definitions
- `scene/wave_director.gd`
- Minimal changes to `scene/game.gd`, `scene/game.tscn`, `scene/enemy.gd`, and
  `scene/game_session.gd`
- `tests/phase9_smoke.gd` and a scene-backed Phase 9 integration harness
- Shared architecture, mechanics, implemented-features, and progress docs

## Implementation passes

1. Re-audit current code and confirm it still matches the approved completion,
   `current_round`, and completion-reward decisions in the proposal.
2. Implement and test WaveConfig validation plus pure WaveDirector state.
3. Add explicit one-shot enemy defeat notification if required.
4. Integrate existing Game spawning and HUD without changing terminal paths.
5. Verify level-up pause/resume and ordinary wave completion.
6. Verify Boss, death, Shop, and reward regressions.
7. Run compatible runtime/headless Phase 1-9 suite, inspect diff, and update
   progress.

## Definition of done

- All Phase 9 acceptance checks pass through real runtime/headless tests.
- No Phase 10 multi-weapon or Shop overhaul work appears in the diff.
- Resource data owns pacing numbers; Game contains no duplicated wave tables.
- Existing result, Boss, XP, level-up, and Shop flows remain one-shot.

## Dependencies

Phase 8 must remain green. Pause and ask only if current code contradicts the
approved Phase 9 decisions or a new destructive/data-contract choice appears.
