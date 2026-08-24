# Phase 3 Proposal: Independent Weapon System

## Goal

Move projectile configuration and firing mechanics into a data-driven weapon
Resource and `WeaponSystem`, while keeping Player responsible for input,
aiming, movement, and cooldown orchestration.

## Scope

- `WeaponConfig` defines damage, cooldown, projectile count, spread, speed,
  range, piercing, tags, and upgrade level.
- The starter weapon is represented by `weapon_basic.tres`.
- `WeaponSystem` creates configured bullets and supports spread and piercing.
- Existing collision and lifetime behavior remains compatible.

## Non-goals

Weapon shop offers, upgrade UI, synergies, and multiple weapon slots remain
future work. Character stat resolution remains owned by `GameSession`.

## Acceptance checks

1. Weapon resources and scripts compile after editor startup.
2. Player owns a `WeaponSystem` and fires configured bullets through it.
3. Bullet damage, speed, range, and piercing are data-driven.
4. Phase 3 smoke failures return a non-zero exit code.
