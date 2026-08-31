# Phase 11 Tasks: Shop Inventory and Weapon Combining

## Shared inputs and guardrails

All tasks read `docs/phase11-proposal.md`, `docs/phase11-design.md`, Phase 10 design/tasks, and
`docs/tasks/progress.md`. GameSession owns rules and atomic state; Shop owns UI only. WeaponConfig
and RelicData remain immutable. Do not add generic Items, permanent saves, combat refactors, or
Phase 12 behavior.

## Task 1 — Offer metadata and GameSession inventory model

**Objective:** Establish the minimum Resource metadata and defensive three-slot runtime model.

**Expected files:** `resourse/weapon/weapon_config.gd`, `resourse/relic/relic_data.gd`, reviewed
Weapon/Relic `.tres`, `scene/game_session.gd`, focused Task 1 smoke.

**Implementation:** Add rarity/positive shop weight only; define constants and type-qualified offer
snapshots; add inventory initialization/getters and catalog validation without purchase, lock or
reroll behavior.

**Checks:** valid metadata; unique IDs; exactly three ordered slots including graceful empty slots;
defensive copies; no Resource mutation.

**Done:** focused Godot 4.7.1 headless smoke passes and no Phase 10 semantics change.

**Dependencies:** Phase 10 DONE.

## Task 2 — Mixed weighted Weapon + Relic generation

**Objective:** Generate legal mixed offers deterministically from both catalogs.

**Expected files:** `scene/game_session.gd`, Task 2 focused smoke; Resource values only if Task 1
validation identifies an approved metadata gap.

**Implementation:** Build eligibility filters and weighted sampling without replacement; exclude
owned relics, max-level weapons, unowned weapons at full capacity, locked/existing offer IDs; allow
empty slots when exhausted; accept injected RNG.

**Checks:** all draws are legal; no same-inventory duplicate; seeded repeatability; weighted pool
exhaustion terminates; no generic Item type.

**Done:** focused smoke proves invariants and Resource immutability.

**Dependencies:** Task 1.

## Task 3 — Per-offer lock transaction

**Objective:** Add independent slot locks owned by GameSession.

**Expected files:** `scene/game_session.gd`, Task 3 focused smoke.

**Implementation:** Add validated lock setter/toggle and preserve locked slot identity/position in
replacement planning; empty/out-of-range slots fail; reset behavior is covered but UI is deferred.

**Checks:** one lock does not affect other slots; locked offers survive replacement; repeated lock
request has no collateral mutation; empty/invalid input is safe.

**Done:** focused smoke passes with snapshots proving independent state.

**Dependencies:** Task 2.

## Task 4 — Scaling reroll transaction

**Objective:** Move complete reroll state and atomic replacement into GameSession.

**Expected files:** `scene/game_session.gd`, Task 4 focused smoke.

**Implementation:** Compute `5 + 2 * count`; preserve locked slots; regenerate every unlocked slot
in temporary state; atomically deduct/increment/swap; reject all-locked and underfunded actions; no
reroll cap.

**Checks:** 5/7/9 prices, counter semantics, locked persistence, unlocked refresh, insufficient
funds/all locked/corrupt input full-state no-op.

**Done:** focused smoke passes and the Phase 6 compatibility entry remains intentional/documented.

**Dependencies:** Tasks 2-3.

## Task 5 — Atomic purchase and duplicate Weapon upgrade

**Objective:** Purchase an inventory slot atomically and refill it.

**Expected files:** `scene/game_session.gd`, Task 5 focused smoke.

**Implementation:** Validate slot plus expected offer ID; route relic, new weapon, and owned weapon
actions; duplicate weapon raises exactly one Run level; reject max/full/stale/invalid/underfunded
actions; refill purchased slot unlocked or leave empty when exhausted.

**Checks:** exact coin changes; no weapon copies; max level excluded/rejected; successful relic
invalidates existing modifier cache; every failure preserves coins, ownership, levels, inventory,
locks and counter; Resources unchanged.

**Done:** focused smoke passes and Phase 10 transaction/loadout tests remain green.

**Dependencies:** Tasks 2-4.

## Task 6 — Shop UI wiring and live refresh

**Objective:** Replace Shop-owned offer rules with a three-row GameSession-backed presentation.

**Expected files:** `scene/shop.gd`, `scene/shop.tscn`, Task 6 scene/focused integration tests;
`scene/game_session.gd` only for a proven interface gap.

**Implementation:** Render snapshots, prices, levels, rarity and locks; forward purchase/lock/reroll
commands; refresh after every result; preserve coins, Continue and Shop -> Game flow. Remove Shop as
an authoritative random/catalog transaction owner.

**Checks:** exactly three rows including empty state; button availability mirrors GameSession;
purchase refill, lock, reroll price and failure feedback refresh immediately; no duplicate signal
connections or hidden transaction logic.

**Done:** real scene integration passes and Task 5 Phase 10 Shop behavior is preserved through the
new inventory contract.

**Dependencies:** Tasks 1-5.

## Task 7 — Reset, runtime integration, regression, and documentation closeout

**Objective:** Prove Run lifecycle and close Phase 11 only after full compatible verification.

**Expected files:** Phase 11 focused/integration tests and shared status docs; gameplay files only
for a focused test-proven Phase 11 defect.

**Implementation:** Cover reset/reload, scene persistence within a Run, new-Run clearing, Resource
immutability and transaction atomicity; run Phase 1-11 compatible suite; update progress only after
green runtime results.

**Checks:** reset clears inventory/locks/counter and restores price 5; reload cannot retain old Run
state; Phase 10 multi-weapon/modifier/Shop behavior, Wave/Boss and integrations remain green;
`git diff --check` and final diff contain no Phase 12/permanent-state work.

**Done:** Godot 4.7.1 headless focused and required regressions exit 0; Phase 11 may then be marked
DONE. Phase 12 remains unstarted.

**Dependencies:** Tasks 1-6.

## Dependency order

```text
Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5 -> Task 6 -> Task 7
```

The sequence is deliberately linear because later transactions consume the exact inventory model
and eligibility rules. UI work starts only after GameSession contracts are independently verified.

