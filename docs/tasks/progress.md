# Progress

## Current status

Phases 1-9 are implemented and runtime-verified. Phase 10 Tasks 1-6 are
implemented and runtime-verified; Phase 10 is DONE. Phase 11 product planning,
design, and task decomposition are complete; Tasks 1-5 are runtime-verified
and Tasks 6-7 have not started. Phase 11 is not DONE.

## Tasks

- [x] Phase 1: stabilize MainMenu -> Game -> Shop -> Game.
- [x] Phase 2: character Resources, selection flow, and multi-attribute resolver.
- [x] Phase 3: independent weapon Resource, firing system, and projectile stats.
- [x] Phase 4: data-driven weapon synergies and non-recursive resolution.
- [x] Phase 5: complete Boss round spawn, combat signals, reward, timeout, and Shop transition.
- [x] Phase 6: weapon offers, weapon upgrades, rerolls, and current-run transaction boundaries.
- [x] Phase 7: balance resource validation, Boss HUD feedback, and repeatable smoke validation.
- [x] Phase 8: run-scoped XP, levels, physical XP drops, and paused three-choice upgrades.
- [x] Phase 9: data-driven wave director and run pacing.
- [x] Phase 10: real multi-weapon loadout — Tasks 1-6 complete and verified.
- [x] Phase 11: Shop inventory and duplicate-weapon combining — Tasks 1-7 complete and runtime-verified.
- [ ] Phase 12: item ecosystem and build tradeoffs (roadmap only).
- [ ] Phase 13: enemy factions, elites, and composition rules (roadmap only).
- [ ] Phase 14: original tactical-industrial presentation pass (roadmap only).
- [ ] Phase 15: finite run milestones and final encounter (roadmap only).
- [ ] Phase 16: balance, performance, and release verification (roadmap only).

## Commands run

- `godot --headless --path . --editor --quit`
- `godot --headless --path . --editor --check-only --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase2_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase1_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase3_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase4_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_smoke.gd`
- `godot --headless --path . --editor --script res://tests/phase5_integration_smoke.gd`
- `godot <compatible-headless-options> --script res://tests/phase8_smoke.gd`
- `godot <compatible-headless-options> --scene res://tests/phase8_integration.tscn`
- Phase 1-8 smoke and all Phase 5/8 integrations were run with isolated
  `APPDATA`, Dummy audio, headless display, `gl_compatibility`, and OpenGL 3.
- `godot <compatible-headless-options> --script res://tests/phase9_smoke.gd`
- Phase 9 first-pass smoke and the Phase 8 regression smoke passed with the
  same isolated runtime setup on 2026-08-27.
- `godot <compatible-headless-options> --scene res://tests/phase9_game_integration.tscn`
- Phase 9 Game integration, Phase 8 smoke, and Phase 8 integration passed with
  the isolated runtime setup on 2026-08-27.
- `godot <compatible-headless-options> --script res://tests/phase10_task1_smoke.gd`
- Phase 10 Task 1 focused smoke, Phase 1-9 smoke, Phase 5 integration smoke,
  and Phase 5/8/9 integration scenes passed on 2026-08-28. The certificate and
  cleanup warnings did not affect exit codes.
- `godot <compatible-headless-options> --script res://tests/phase10_task2_smoke.gd`
- Phase 10 Task 2 focused smoke plus the Phase 1-9 smoke/regression set passed
  on 2026-08-28. Expected invalid-input errors, certificate, and cleanup
  warnings did not affect exit codes.

## Phase 2 decisions

- `GameSession` owns selected-character identity and cached resolution state.
- Base values are resolved before relic bonuses; additive effects and
  multiplicative effects use separate, deterministic passes.
- Resolved results are clamped and continuous values are rounded to three
  decimals; integer values are rounded to the nearest integer.
- Damage, projectile count, starting weapon, and passive are data contracts for
  Phase 3. Existing Player shooting behavior is intentionally unchanged.
- Pickup range uses a dedicated Area2D so the existing Player body collision
  shape and direct-contact collection remain compatible.

## Known environment risk

Godot 4.7.1 still logs a Windows root-certificate-store warning. Isolated
`APPDATA` plus Dummy audio and headless OpenGL compatibility avoids the former
runtime crash and all current tests exit successfully.

## Phase 3 decisions

- `WeaponConfig` owns projectile combat parameters; `WeaponSystem` owns bullet
  construction and spread; Player remains input and movement orchestration.
- Bullet range and piercing are resolved per projectile and do not mutate
  character stats.

## Phase 4 decisions

- Synergies require a set of weapon tags and are resolved from the equipped set.
- Resolution applies each matching synergy once from base weapon stats; repeated
  calls do not compound bonuses.

## Next step

Begin Phase 11 Task 5 only: atomic purchase and duplicate Weapon upgrade. Tasks 6-7 and Phase 12
have not started; Phase 11 remains not DONE.

## Phase 11 Task 1 acceptance

- WeaponConfig and RelicData expose minimal `COMMON/UNCOMMON/RARE` rarity and
  positive `shop_weight` metadata without changing combat, level, price, or
  modifier semantics.
- GameSession owns a resettable ordered three-slot runtime inventory with
  type-qualified offer IDs, primitive snapshots, catalog validation, and a
  defensive snapshot getter.
- `tests/phase11_task1/phase11_task1_smoke.gd` passed under Godot 4.7.1
  headless. Phase 1/2 and Phase 10 Task 1-6 regressions also passed.
- Task 1 did not implement weighted generation, lock, reroll, purchase/refill,
  Shop UI, or any Phase 12 behavior.

## Phase 11 Task 2 acceptance

- `GameSession.ensure_shop_inventory(rng)` now builds a mixed Weapon + Relic
  candidate pool, filters invalid/ineligible entries, and samples by finite
  positive `shop_weight` without replacement using injected or production RNG.
- Owned relics, max-level weapons, and unowned weapons at full loadout are
  excluded; candidate exhaustion leaves `{}` slots and initialized inventories
  are not rerolled by a second ensure call.
- `tests/phase11_task2/phase11_task2_smoke.gd` passed under Godot 4.7.1
  headless. Task 1, Phase 1/2, and Phase 10 Task 1-6 regressions passed.
- Task 2 did not implement lock, reroll, purchase/refill, Shop UI, Task 7
  integration, or any Phase 12 behavior.

## Phase 11 Task 3 acceptance

- `GameSession.set_shop_offer_locked(slot_index, expected_offer_id, locked)`
  validates slot, populated offer, and stale UI identity before changing only
  the target runtime snapshot.
- Lock and unlock are independent and idempotent; invalid/empty slots and
  mismatched IDs are no-ops. Locking consumes no RNG, does not rerun inventory
  generation, and defensive snapshots cannot mutate authoritative lock state.
- `reset_run()` clears the inventory and all lock state. WeaponConfig and
  RelicData remain immutable.
- `tests/phase11_task3/phase11_task3_smoke.gd` passed under Godot 4.7.1
  headless. Tasks 1-2, Phase 1/2, and Phase 10 Task 1-6 regressions passed.
- Task 4 reroll, Task 5 purchase/refill, Task 6 UI, Task 7 integration, and all
  Phase 12 behavior remain unimplemented.

## Phase 11 Task 4 acceptance

- `GameSession` owns the current reroll price (`5 + 2 * count`) and an atomic
  reroll transaction that preserves locked slots while rebuilding unlocked
  slots through the existing mixed weighted, without-replacement generator.
- Underfunded, uninitialized, malformed, all-locked, and corrupt-counter
  requests are no-ops. Validation failures do not consume injected RNG;
  successful rerolls deduct once, increment once, and commit one replacement.
- Candidate exhaustion leaves empty unlocked slots, snapshots remain defensive,
  Resources remain immutable, and `reset_run()` restores count 0 and price 5.
- `tests/phase11_task4/phase11_task4_smoke.gd` passed under Godot 4.7.1
  headless. Tasks 1-3, Phase 1/2, and Phase 10 Task 1-6 regressions passed.
- Task 5 purchase/refill, Task 6 UI, Task 7 integration, and all Phase 12
  behavior remain unimplemented.

## Phase 10 planning checkpoint

- Proposal, detailed design, and six minimal verifiable implementation slices are drafted.
- Chosen direction: ordered three-slot loadout, per-ID Run levels, shared aim,
  independent WeaponSystem cooldowns, and GameSession-owned atomic transactions.
- No Task 3-6 gameplay or final Phase 10 acceptance is claimed by this checkpoint.
- Task 1 is implemented: GameSession owns a validated ordered three-slot
  loadout, per-ID Run levels, CharacterConfig-derived reset, atomic purchase and
  upgrade transactions, and defensive query snapshots.
- Task 2 is implemented: WeaponConfig exposes explicit per-level stat
  resolution with shared level bounds, invalid-input rejection, copied results,
  and Resource immutability.
- Task 3 is implemented and runtime-verified with independent per-weapon entries,
  cooldowns, GameSession Run levels, and Task 2 stat resolution.
- Task 4 is runtime-verified: Character, Relic, XP, synergy, and temporary
  attack modifiers resolve idempotently across every weapon runtime entry.
- Task 5 is runtime-verified: Shop presents weapon offers and equipped levels,
  performs atomic purchase/upgrade transactions, handles full slots, and refreshes state.
- Task 6 is complete and runtime-verified; Phase 10 is DONE. Phase 11 remains
  unstarted.
- Task 6 focused smoke and Phase 11 Tasks 1-5 regressions pass under isolated
  headless runtime; Phase 10 Task 5 smoke now validates authoritative
  GameSession purchase/upgrade flow.

## Planning checkpoint

- `docs/development-roadmap.md` defines the Phase 9-16 sequence.
- `docs/visual-direction.md` defines an original industrial-frontier tactical
  style and explicit non-copying boundaries.
- `docs/phase9-proposal.md`, `docs/phase9-design.md`, and
  `docs/tasks/phase9-wave-director.md` are ready for the next workflow cycle.
- Phase 9 gameplay integration is now present in Game; final phase acceptance
  still requires the broader Phase 1-9 regression sweep.

## Phase 7 decisions

- Balance values remain in Resource assets; HUD reads runtime Boss state only.
- No persistence, new progression systems, or scene ownership changes were added.

## Final acceptance

- Phase 1-7 smoke scripts all pass editor `--check-only` without parse or load errors.
- Phase 1-7 smoke scripts and both Phase 5 integration harnesses pass real
  runtime/headless execution when Godot uses an isolated writable `APPDATA`,
  Dummy audio, and the headless OpenGL compatibility renderer.
- The remaining root-certificate-store warning is environmental and does not
  affect the local runtime suite result.

## Phase 5 runtime regression fix

- Dynamically constructed Boss instances now listen for the Bullet collision
  layer, matching the existing Bullet/Enemy damage contract used in Game.
- Boss timeout is terminal and emits exactly once rather than once per frame.
- Runtime tests now set up Boss configuration before tree entry, wait for the
  correct physics/process frames, and observe signals through persistent test
  state. Phase 3/4 runtime smoke tests validate loaded scripts without trying
  to reload scripts that already have live instances.

## Phase 5 decisions

- Boss behavior is isolated in `Boss` and configured by `BossConfig`; ordinary
  `EnemyConfig` remains unchanged.
- Health thresholds select a single current phase without recursive effects.
- Telegraph, timeout, phase change, and one-shot defeat reward are signals so
  `Game` can own scene transitions and `GameSession` can own run rewards.
- Boss spawning is gated by `BossConfig.spawn_round`; defeat credits
  `GameSession.current_coins` before the existing Shop transition.

## Phase 8 decisions

- GameSession owns XP, thresholds, queued level-ups, offers, and chosen upgrade
  stacks; no permanent or cross-run state was introduced.
- XP uses a dedicated physical pickup while reusing the existing Pickup layer
  and Player pickup-range collision contract. Coin behavior remains unchanged.
- Upgrade Resources are immutable; character/relic stats resolve first, then
  Phase 8 stacks. Live choices update Player and WeaponSystem immediately.
- Game pauses the scene tree for choices without changing `Engine.time_scale`;
  result dialogs and scene transitions retain their existing terminal control.

## Phase 9 first-pass decisions

- Three immutable WaveConfig resources define distinct pacing and weighted
  pools using existing EnemyConfig resources.
- WaveDirector is pure runtime state: it requests spawns, but consumes budget
  only after Game confirms that an enemy was constructed.
- Duration completion, caps, budgets, and duplicate defeat notifications are
  guarded and covered by the focused smoke test. Game integration remains the
  next bounded pass.

## Phase 9 Game integration decisions

- Ordinary rounds advance WaveDirector from Game; the legacy EnemySpawnTimer is
  reserved for Boss rounds.
- Game commits spawn state only after successful Enemy construction; Enemy emits
  one idempotent `defeated` signal from its existing death entry point.
- Existing HUD labels/time bar show wave, remaining seconds, and kill progress.
- Completion coins are credited once before the existing Shop transition.

## Phase 9 final acceptance

- Full Phase 1-9 smoke regression passed under isolated APPDATA, Dummy audio,
  headless display, gl_compatibility, and OpenGL 3 on 2026-08-27.
- Phase 5, Phase 8, and Phase 9 integration scenes passed in the same runtime.
- Temporary generated `.uid` files from test execution were removed; no Phase
  10 code or unrelated refactor was added.

## Phase 8 runtime verification

- Phase 1-8 smoke scripts passed with isolated `APPDATA`, Dummy audio, headless
  display, `gl_compatibility`, and OpenGL 3.
- `tests/phase5_integration.tscn`, `phase5_integration_smoke.gd`, and
  `tests/phase8_integration.tscn` passed under the same real runtime setup.
- The Windows root-certificate-store warning remains environmental and does
  not change test exit codes.
