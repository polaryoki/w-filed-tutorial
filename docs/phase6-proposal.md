# Phase 6 Proposal: Expanded Shop and Run Progression

## Goal

Extend the existing between-round Shop with run-scoped weapon offers, weapon
upgrades, and rerolls. All purchases remain temporary `GameSession` state;
permanent currency, saves, and meta-progression are explicitly out of scope.

## Requirements

- Offer a data-driven weapon that can be equipped once per run.
- Upgrade an equipped weapon atomically when the player can afford it.
- Allow a reroll that deducts a configured cost and refreshes shop offers.
- Reject duplicate, invalid, and under-funded transactions without mutating
  coins or progression.
- Preserve the existing Game -> Shop -> next round flow and Player/Weapon
  responsibilities.

## Success criteria

`GameSession` is the single transaction boundary; a smoke test verifies weapon
purchase/equip, upgrade level and coin deduction, reroll count/cost, and failure
invariants. Existing Phase 1-5 checks continue to pass.

## Non-goals

No permanent saves, multi-shop currencies, complex UI redesign, or Phase 7
balance/presentation work.
