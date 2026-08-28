# 待开发功能

以下项目是基于当前代码的规划，不代表已经实现。

## 高优先级

- 金币系统增强：金币拾取音效、动画和更丰富的掉落平衡。
- 明确并统一资源路径大小写（当前部分场景引用存在 `scene`/`Scene` 不一致风险）。
- 为攻击、死亡、掉落和胜负流程增加可重复的运行时验证。

## 中优先级

- 玩家死亡动画和死亡音效流程。
- 子弹伤害配置化（而不是固定为 1）。
- 更明确的敌人掉落事件/信号，降低敌人脚本与掉落实现的耦合。
- 关卡重新开始、暂停和结果界面的完整交互。
- 更完整的 HUD：金币、Buff 剩余时间、击杀数等。

## 长期方向

- 跨关卡金币存档与商店/升级系统。
- 更多敌人、武器、掉落物和关卡配置。
- 自动化测试、性能监控和发布流程文档。

## 金币方案摘要

金币基础系统已实现：复用 `Pickup` 的物理层，新增加 `Coin` 场景、`Player.add_coins()` 接口和金币 HUD；在 `Enemy._die()` 的统一入口按 `EnemyConfig` 配置生成金币。后续仍需决定跨关卡保存、磁吸行为、金币动画和更细的掉落平衡。

## Round and Shop Follow-ups

- Shop item configuration and progression balancing remain future work.
- Cross-run coin saving is not implemented; GameSession coins are only for the current run.
## Relic Follow-ups

- Add more relics and balance prices/effects.
- Balance the expanded six-relic pool.
- Add relic icons and richer item presentation.
- Add more advanced shop refresh and relic upgrade mechanics.

## Project Expansion Roadmap

The following roadmap is ordered from foundational systems to larger gameplay features. Each item requires a separate design pass before implementation.

### Phase 1: Stabilize current run systems

- Fix and verify all Shop/Relic UI paths with Godot runtime checks.
- Add focused validation for GameSession reset, coin handoff, relic purchase, and cross-round effect resolution.
- Keep current Player, Coin, Pickup, Enemy, and round timer behavior unchanged while adding tests.

### Phase 2: Character data and multi-attribute system

- Add character Resource definitions with base health, move speed, fire interval, damage, projectile count, pickup range, luck, armor, and critical chance where supported.
- Add character selection after MainMenu or before the first Game scene.
- Resolve character attributes plus relic/run bonuses once per round.
- Define stacking, caps, and display rules before adding more attributes.

### Phase 3: Independent weapon system

- Define weapon Resources for damage, cooldown, projectile count, spread, speed, range, piercing, and tags.
- Separate weapon firing from Player input orchestration without rewriting movement.
- Support multiple equipped weapons and per-run weapon upgrades.
- Preserve the existing Bullet collision and lifetime behavior unless a weapon requirement proves a minimal extension necessary.

### Phase 4: Weapon synergy system

- Add weapon tags and a data-driven synergy definition.
- Resolve synergies from the equipped weapon set.
- Apply synergy bonuses once to resolved weapon stats and prevent recursive stacking.
- Add clear Shop and HUD feedback for active synergies.

### Phase 5: Boss battle system

- Define BossConfig Resources for health, phases, attacks, movement, rewards, and spawn rules.
- Add a configured boss round or wave threshold.
- Define boss success, failure, reward, and transition behavior.
- Keep boss logic separate from ordinary Enemy configuration where behavior is materially different.

### Phase 6: Expanded Shop and run progression

- Add weapon offers, weapon upgrades, character upgrades, rerolls, and optional shop locks.
- Define shop inventory generation and refresh costs.
- Add boss rewards and run milestones.
- Keep all temporary progression in GameSession until permanent saves are explicitly designed.

### Phase 7: Balance and presentation

- Add relic/weapon/character balance data and difficulty curves.
- Add boss telegraphs, UI feedback, audio, and pixel-art icons.
- Add automated smoke tests and repeatable run validation.

### Long-term, not yet approved

- Permanent currency and save files.
- Meta-progression and unlocks.
- More complex enemy factions and multi-stage bosses.
- Online features or external plugins.

## Active roadmap after Phase 8

The original Phase 1-7 roadmap above is historical. Current planning continues
in `docs/development-roadmap.md`; use `docs/continuation.md` as the next-session
entry point.

Immediate priority:

1. Phase 9 data-driven WaveConfig and WaveDirector.
2. Preserve Phase 8 XP/level-up pause behavior during wave timing.
3. Add deterministic wave/runtime integration tests before content expansion.

Phase 10 real multi-weapon loadout planning is complete and awaits review;
implementation has not started from the accepted Phase 1-9 baseline. Phase 11
Shop inventory/combining remains out of scope and requires a separate design pass.

Later phases cover real multi-weapon builds, Shop combining, item tradeoffs,
enemy composition, an original industrial-tactical presentation pass, finite
run milestones, and final balance/performance verification. Permanent saves,
meta progression, networking, achievements, advertising, and purchases remain
out of scope until explicitly approved.
