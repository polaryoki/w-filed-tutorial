# Phase 6 Task: Shop and Run Progression

## Objective

Deliver the expanded Shop transaction layer without changing the established
round flow or introducing permanent progression.

## Inputs

- `docs/phase6-proposal.md`
- `docs/phase6-design.md`
- `docs/architecture.md`
- `docs/game-mechanics.md`

## Expected files

`scene/game_session.gd`, `scene/shop.gd`, weapon Resources, and
`tests/phase6_smoke.gd`.

## Checks

- Known weapon can be equipped once; duplicate/unknown offers fail safely.
- Equipped weapon upgrade increments one level and deducts exactly its price.
- Insufficient funds and invalid prices leave all state unchanged.
- Reroll deducts its configured cost and increments count once.
- Run reset clears upgrades, equipped weapons, coins, and reroll count.

## Definition of done

Phase 6 smoke passes, prior phase smoke checks remain green, and docs reflect
the implemented run-only scope. No permanent save or Phase 7 work is included.
