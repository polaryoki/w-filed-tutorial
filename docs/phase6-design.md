# Phase 6 Design

## Boundaries

`Shop` presents offers and forwards button actions. `GameSession` owns the
current-run currency, equipped weapon IDs, upgrade levels, and reroll count.
`WeaponConfig` remains the data source; `WeaponSystem` and `Player` keep their
existing combat responsibilities.

## Transactions

- Weapon offer: validate a known weapon, deduct its price, then equip; failed
  validation must refund/no-op.
- Upgrade: requires an equipped weapon and sufficient coins; increment exactly
  one level after deduction.
- Reroll: requires sufficient coins; deduct cost and increment
  `shop_reroll_count`; offer regeneration is presentation-owned.

All operations are idempotent with respect to duplicate purchases and reject
non-positive prices. `reset_run()` clears these fields at run start.

## Verification

`tests/phase6_smoke.gd` exercises the real autoload transaction methods and
asserts coin, ownership, level, and reroll invariants. Scene loading and full
runtime checks remain covered by the existing suite.
