# Phase 3 Design

`WeaponConfig` is immutable run data. `WeaponSystem` receives a config and
owns projectile construction; Player passes the origin, aim direction, current
scene, and world-spawn validation callback. Bullet stores the resolved combat
values and enforces range and piercing independently of Player.

The existing Player timer and input path are preserved. Character `damage` and
`projectile_count` fields remain available as data contracts, but weapon
configuration is authoritative for projectile behavior. This prevents weapon
logic from leaking into character resolution and leaves room for future
equipped-weapon collections and upgrades.
