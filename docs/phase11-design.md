# Phase 11 Design: Shop Inventory and Weapon Combining

## 1. Ownership

`GameSession` owns inventory generation, slots, locks, reroll count/price, candidate validation,
purchase resolution, currency commits, refill, and reset. `Shop` renders snapshots and forwards
slot actions. WeaponConfig and RelicData supply immutable catalog data. No Shop state is combat
state, and WeaponSystem does not read the inventory.

```text
WeaponConfig / RelicData catalogs
             -> GameSession candidate resolver + RNG
             -> three runtime offer slots
Shop UI <---- snapshots / commands ----> GameSession atomic transactions
             -> equipped weapon levels / owned relics / coins
```

## 2. Minimal Resource metadata

Both existing Resource scripts receive two minimal, identically interpreted fields during
implementation:

- `rarity`: a small enum such as `COMMON`, `UNCOMMON`, `RARE`; display/category metadata only.
- `shop_weight: float`: finite positive selection weight.

RelicData already owns `price`. WeaponConfig remains combat-authoritative and immutable; Phase 11
may add only Shop metadata required by offers. To preserve current balance boundaries, weapon
prices remain GameSession constants: 12 for a new weapon and 10 for a duplicate upgrade. Rarity
does not modify stats, price, or upgrade growth. Selection uses `shop_weight` directly, so the
design does not create a second rarity probability table or a generic Item hierarchy.

Invalid catalog entries (null Resource, empty/duplicate ID, unsupported rarity, non-finite or
non-positive weight, or non-positive relic price) are excluded, never repaired at runtime.

## 3. Offer runtime data

GameSession stores exactly three ordered slot dictionaries. A populated snapshot has:

```gdscript
{
    "slot_index": 0,
    "offer_id": &"weapon:basic",
    "offer_type": &"weapon", # or &"relic"
    "content_id": &"basic",
    "rarity": 0,
    "weight": 1.0,
    "price": 10,
    "locked": false,
}
```

`offer_id` is type-qualified so a Weapon and Relic may share a content ID without collision.
`price`, rarity and weight are runtime copies for display and transaction identity; transactions
re-resolve authoritative catalog/state before commit. An empty slot is `{}`. Public getters return
deep copies so Shop cannot mutate GameSession state.

GameSession runtime fields:

- `shop_inventory: Array[Dictionary]`, always three slots after initialization.
- `shop_reroll_count: int`, number of successful rerolls in this Run.
- constants `SHOP_INVENTORY_SIZE = 3`, `SHOP_REROLL_BASE_PRICE = 5`,
  `SHOP_REROLL_PRICE_STEP = 2`, new weapon price 12, duplicate upgrade price 10.

No Resource reference is required in persisted runtime slots; IDs are resolved through the two
catalogs. There is no permanent serialization.

## 4. Candidate eligibility

A candidate is derived from each valid Resource:

- Relic: eligible only when not owned.
- Owned Weapon: eligible when its level is valid and below `MAX_WEAPON_LEVEL`; price is 10 and
  purchase action is upgrade.
- Unowned Weapon: eligible only when `equipped_weapon_ids.size() < MAX_WEAPON_SLOTS`; price is 12
  and purchase action is equip.

The generator excludes offer IDs already present in other populated inventory slots, including
locked slots. Therefore one inventory never contains duplicate `offer_type + content_id` entries.
Weapon and Relic candidates share one weighted pool; `shop_weight` is the positive draw weight.
Each selected candidate is removed from the pool before the next slot draw.

If no legal candidate remains, the slot is `{}`. Generation terminates normally even if all three
slots are empty. It never inserts an owned relic, max-level weapon, unaffordable-only surrogate,
or generic Item.

## 5. Inventory initialization and refill

`ensure_shop_inventory(rng = null)` generates only when inventory is uninitialized. A provided
`RandomNumberGenerator` is used directly for deterministic tests; production creates and
randomizes one. Scene reload within a Run reads the existing inventory rather than rolling again.

After a successful purchase, the selected slot is cleared and refilled immediately using the same
eligibility rules while excluding the two remaining offers. Refill uses a caller-injected RNG in
the transaction API for tests. The new slot is unlocked. If no candidate exists, it remains empty.

## 6. Weighted draw

For a candidate list with weights `w[i] > 0`, calculate the finite total, draw a float in
`[0, total)`, then choose the first cumulative weight greater than the draw. Stable catalog order
is retained before drawing, allowing seeded RNG tests. Invalid weights are filtered before total
calculation. Selection is without replacement within the current inventory.

## 7. Lock transaction

`set_shop_offer_locked(slot_index, locked) -> bool` validates an initialized, populated slot and
boolean target. It changes only that slot. Repeating the current value succeeds as an idempotent
no-op or returns a documented unchanged result; tests must assert no collateral mutation. Empty or
out-of-range slots fail. Lock has no coin cost. A purchased slot loses its old lock; reset clears
all slots and locks. There is no global lock.

## 8. Reroll transaction

`get_shop_reroll_price() -> int` returns:

```text
5 + 2 * shop_reroll_count
```

`try_reroll_shop(rng = null) -> bool` performs:

1. Validate initialized inventory, at least one unlocked slot, non-negative counter, sufficient
   coins, and availability of a usable RNG.
2. Build the entire replacement inventory in temporary values, preserving locked dictionaries at
   their original indexes and excluding their offer IDs.
3. Only after successful construction, deduct the current price, increment counter once, and swap
   in the new inventory.

Unlocked slots may become empty when no legal candidate exists; that is a valid constructed
result. Insufficient coins, all slots locked, invalid state or generation failure leaves coins,
counter, slots and locks unchanged. There is no reroll limit.

## 9. Purchase transaction and duplicate resolution

`try_purchase_shop_offer(slot_index, expected_offer_id, rng = null) -> bool` requires the caller's
expected ID to match the current slot, preventing stale UI actions.

Validation order:

1. Valid populated slot and matching type-qualified offer ID.
2. Catalog Resource still exists and remains valid.
3. Offer price matches the authoritative current action price and is positive.
4. Sufficient coins.
5. Relic is unowned; or Weapon is either an eligible new equip with capacity, or an owned valid
   level below max.
6. A replacement slot can be computed (empty is allowed).

Commit occurs once:

- Relic: deduct price, append relic ID, invalidate character resolution.
- New Weapon: deduct 12, append one weapon ID, set level 1.
- Owned Weapon: deduct 10, increment that weapon's Run level exactly once.
- Clear the purchased slot and install the unlocked refill.

No Resource is mutated. Failure changes none of coins, ownership, levels, inventory or locks. The
existing lower-level Phase 10 transaction methods remain valid compatibility APIs; the Phase 11
Shop must use the slot transaction so inventory and currency commit together.

## 10. Reset and scene lifecycle

`reset_run()` clears `shop_inventory`, sets `shop_reroll_count` to 0, and thereby restores price 5.
The next Shop initialization creates new offers with no locks. Reloading Shop without reset uses
the current slots and locks. Reloading Game does not copy Shop state into Player or WeaponSystem.

## 11. Shop UI

Shop builds three reusable rows from GameSession snapshots. Each row shows type, display name,
rarity, price, weapon level/action where relevant, purchase availability, and a per-slot lock
toggle. It also shows coins and the computed reroll price. After purchase, lock, or reroll it asks
GameSession for a fresh snapshot and redraws all rows. Empty slots show an unavailable state.

Shop does not shuffle catalogs, decide eligibility, calculate action price, deduct coins, alter
levels/owned relics, or retain a second authoritative `displayed_weapons/displayed_relics` model.
Continue and existing round transition behavior remain unchanged.

## 12. Invalid input behavior

Out-of-range slots, empty slots, stale offer IDs, unknown types/IDs, invalid Resource metadata,
non-positive or mismatched prices, illegal weapon levels, max level, full loadout, duplicate relic,
negative counter and insufficient funds are safe failures. Public snapshots are defensive copies.
No operation silently clamps corrupt transaction state into a purchase.

## 13. Atomicity and Resource immutability

Transactions construct and validate candidate state before mutation. Tests snapshot coins,
inventory, locks, owned relics, loadout, levels, counter and Resource properties before each
failure case and compare all afterward. Runtime offer fields are copied primitives; Resource
rarity/weight/price/combat fields are never written.

## 14. Deterministic testing strategy

- Catalog validation smoke: unique IDs, supported rarity, positive finite weights/prices.
- Inventory smoke with seeded RNG: three slots, mixed eligible types across controlled draws,
  weighted selections belong to the legal pool, no duplicate offer IDs, graceful exhaustion.
- Lock smoke: independent locks, locked preservation and unlocked replacement.
- Reroll smoke: prices 5/7/9, counter increments, no upper limit, insufficient/all-locked atomic
  failure.
- Purchase smoke: new weapon, duplicate -> exactly one level, max/full/owned relic/stale ID and
  insufficient-funds failures, refill and lock reset.
- Reset smoke: inventory and locks absent, counter 0, price 5; scene reload within a Run preserves
  state, new Run does not.
- UI integration: three rows reflect GameSession and refresh after every command; Continue flow
  and Phase 10 Shop/runtime behavior remain compatible.
- Regression: Phase 1-10 smoke plus Phase 5/8/9/10 integrations under Godot 4.7.1 headless.

Seeded tests should assert invariants rather than a fragile global random sequence. A small test
catalog or injected RNG may be used; production Resources remain immutable.

## 15. Explicit phase boundary

Phase 11 combining means only `owned duplicate Weapon -> one Run level`. Generic Item inventory,
item stacks, positive/negative item stats, stat sheet, recipes, weapon copies, dismantling and
complex tier fusion remain outside this design and require later approval. Phase 12 is not started.

