# Phase 12 Tasks: Stat Sheet and Roguelite Build Loop

## Task 1 — Modifier contract and stat identifiers

Define the minimal stat IDs, modifier record shape, bounds, and defensive stat-sheet interface.
Expected files: design/task docs and focused smoke only; no Shop or combat changes. Acceptance:
invalid IDs/operations are safe, negative values are representable, snapshots are defensive, and
Task 6/7 tests remain green.

## Task 2 — Deterministic stacking resolver

Implement GameSession-owned aggregation of character base, Relic, and Upgrade modifiers with flat
then percent stacking, stable order, caps, and cache invalidation. Do not move ownership out of
GameSession or alter existing transaction APIs. Focused smoke covers positive/negative stacking,
repeated resolution, reset, and Resource immutability.

## Task 3 — Player and WeaponSystem runtime integration

Consume Final Stat Sheet values in Player and per-weapon WeaponSystem entries. Preserve existing
Phase 10 level resolution, synergies, temporary pickup overrides, and firing APIs. Focused runtime
smoke proves changed movement/health and changed damage/interval/projectile behavior.

## Task 4 — Relic and Upgrade migration

Map current RelicData and UpgradeConfig effects into the modifier contract without changing their
authoritative IDs or purchase/apply semantics. Add at least one negative tradeoff definition.
Focused smoke proves XP choice and Shop purchase both alter the same final sheet and remain atomic.

## Task 5 — Build readability

Add a compact read-only stat/build display at an existing safe UI surface (Shop or gameplay HUD)
without changing Shop snapshot ownership. Focused scene smoke checks values refresh after reset,
upgrade, relic purchase, reload, and Continue.

## Task 6 — Minimal tradeoff content

Add a small number of original Relic/Upgrade examples expressing simultaneous positive and negative
modifiers. No generic item framework or content flood. Smoke checks meaningful alternative builds.

## Task 7 — Full regression and balance baseline

Run Phase 12 focused/integration tests plus Phase 1–11 compatible gates, diff/check-only checks,
and record a baseline of final stats and combat outputs. Only then update progress; Phase 13 remains
unstarted.

## Dependency order

```text
Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6 -> Task 7
```

## First playable slice

Task 1–4 must produce one complete chain: base stat → Relic/Upgrade modifier → Final Stat Sheet →
Player/WeaponSystem runtime value → observable combat difference. Tasks 5–6 improve readability and
choice quality; Task 7 is the closeout gate.
