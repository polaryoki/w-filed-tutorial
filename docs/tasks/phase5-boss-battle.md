# Phase 5 Boss Battle

## Objective
Close the boss round from spawn through combat, reward, timeout, and Shop.

## Files
`scene/boss.gd`, `scene/game.gd`, `scene/game_session.gd`, boss resources, and
`tests/phase5_smoke.gd`.

## Checks
Run all phase smoke scripts with Godot editor check-only and inspect the diff.

## Definition of done
Boss spawns at its configured round, emits telegraphs, accepts bullet-equivalent
damage, rewards once on defeat, handles timeout as failure, and transitions to
the existing round flow.
