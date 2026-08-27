# Development Roadmap After Phase 8

## Product direction

Build an original top-down survival shooter around short combat waves, random
run builds, multi-weapon combinations, level-up choices, and between-wave shop
decisions. The pacing may learn from games such as Brotato, while all character
identities, weapons, items, enemies, terminology, art, UI assets, and balance
must remain original.

The presentation direction is an original industrial-frontier tactical world:
mobile response crews, weathered machinery, hazardous extraction zones, field
terminals, warning markings, and restrained operator-style portraits. It may
use the broad appeal of tactical industrial science fantasy, but must not copy
Arknights factions, operators, silhouettes, logos, UI layouts, terminology, or
story concepts.

## Guiding pillars

1. **Readable combat:** threats, projectiles, drops, damage, and telegraphs are
   understandable at a glance even with many enemies.
2. **Build decisions:** each run creates meaningful combinations through
   weapons, upgrades, relics/items, tags, and tradeoffs.
3. **Short wave rhythm:** combat pressure alternates with clear, fast planning
   breaks in the Shop.
4. **Resource-driven content:** waves, enemies, weapons, upgrades, and items are
   Resources rather than script constants.
5. **Original identity:** industrial tactical presentation supports gameplay
   without reproducing another game's protected content.
6. **Verified increments:** every phase adds runtime/headless smoke and
   integration coverage and preserves earlier tests.

## Planned phases

### Phase 9 — Data-driven wave director and run pacing (next)

- Introduce `WaveConfig`/run pacing Resources and a small `WaveDirector`.
- Replace formula-only spawning with per-wave duration, spawn budget, allowed
  enemy pool, spawn cadence, simultaneous cap, and completion reward data.
- Preserve the current Game -> Shop -> Game transition and Phase 8 level-ups.
- Add wave number, remaining time, and kill progress HUD.
- Validate pause, result, Boss, and level-up arbitration.

### Phase 10 — Real multi-weapon loadout

- Equip several independent weapon instances with separate cooldowns.
- Add original weapon families, firing patterns, slot limits, and tag identity.
- Resolve character, weapon level, synergy, and run-upgrade modifiers through a
  single non-recursive combat-stat path.
- Do not expand Shop inventory rules in the same phase.

### Phase 11 — Shop inventory and weapon combining

- Generate mixed weapon/item offers using rarity and weighted pools.
- Add lock, reroll-cost scaling, purchase feedback, and duplicate combining or
  tier upgrades with atomic GameSession transactions.
- Keep all inventory and currency temporary to the current run.

### Phase 12 — Item ecosystem and build tradeoffs

- Generalize relic-style run modifiers into original items with positive and
  negative stats, rarity, tags, and stack rules.
- Add a readable stat sheet and build summary.
- Expand the upgrade pool only after stacking order and caps are documented.

### Phase 13 — Enemy factions, elites, and wave composition

- Add original industrial-zone enemy families with complementary roles:
  pursuer, ranged pressure, shield, support, splitter, and elite variants.
- Use composition rules and spawn telegraphs rather than raw count alone.
- Add difficulty-budget tests and on-screen readability limits.

### Phase 14 — Tactical-industrial presentation pass

- Apply the original visual bible to HUD, Shop, character selection, upgrade
  cards, icons, hit feedback, warning zones, and audio cues.
- Add original crew identities and portraits only after gameplay contracts are
  stable. Use replaceable placeholders when art is unavailable.
- Preserve accessibility: contrast, scalable UI, color-independent telegraphs.

### Phase 15 — Run structure, milestones, and final encounter

- Define a finite run length, milestone waves, elites, and an original final
  boss encounter using existing Boss ownership.
- Add run summary and current-run build recap.
- No permanent unlocks or save system unless separately approved.

### Phase 16 — Balance, performance, and release verification

- Tune curves using recorded wave/build outcomes rather than ad-hoc constants.
- Pool or cap high-volume entities where profiling proves necessary.
- Add soak tests, pause/transition stress tests, export checks, and release docs.

## Deferred until explicit approval

- Permanent saves, unlock trees, account systems, achievements, networking,
  ads, purchases, live services, and user-generated content.
- Direct imitation or import of third-party characters, items, names, icons,
  story material, UI, sound, art, or numeric balance tables.

## Phase gates

Every phase must begin by reading current docs and code, create/update proposal,
design, and task files, then finish with the compatible runtime/headless suite.
Do not begin the next phase while acceptance checks or documentation remain
incomplete.

