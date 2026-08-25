# Phase 5 Design

`BossConfig` is immutable tuning data. `Boss` owns health, phase, attack timer,
telegraph and terminal signals. `Game` decides when to spawn and how signals
map to scene transitions. `GameSession.add_boss_reward()` is the atomic current-
run reward boundary. Shop remains unchanged and receives the resulting coins.

The encounter uses the existing Game enemy container and Player/Bullet damage
contract (`apply_damage`). No permanent save or new UI framework is introduced.
