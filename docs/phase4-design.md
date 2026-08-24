# Phase 4 Design

`WeaponSynergyConfig` declares required tags and bounded stat bonuses.
`WeaponSynergyResolver.resolve()` unions tags from equipped resources, applies
each matching definition once to fresh stats, and returns active synergy IDs for
HUD/shop presentation. `GameSession` owns equipped weapon IDs; weapon behavior
remains in `WeaponSystem`.
