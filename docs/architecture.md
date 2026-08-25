# 项目架构

## 技术与入口

- 引擎：Godot 4.7，Forward Plus。
- 主场景：`res://scene/main_menu.tscn`，由 `project.godot` 的 `run/main_scene` 指定。
- 主要语言：GDScript。
- 项目采用场景（`.tscn`）与资源配置（`.tres`）分离的结构。

## 目录

- `scene/`：游戏场景和脚本：`Game`、`Player`、`Enemy`、`Bullet`、`Pickup`。
- `resourse/config/`：`EnemyConfig`、`PickupConfig` 及具体资源实例。
- `resourse/animation/`：敌人 SpriteFrames 动画资源。
- `resourse/texture/`：地图、角色、敌人、道具和 UI 素材。
- `resourse/audio/`：背景音乐和游戏音效。
- `release/`：已导出的 Windows 构建产物。

## 运行时关系

`Game` 是编排层，包含 `Player`、`EnemyContainer`、`EnemySpawnPoints`、`EnemySpawnTimer`、世界边界和 HUD。它按计时器生成敌人，并把 `Player` 引用注入每个 `Enemy`。

`Player`（`CharacterBody2D`）负责输入、移动、生命、射击和临时 Buff。射击实例化 `Bullet`。

`Enemy`（`CharacterBody2D`）根据 `EnemyConfig` 初始化，追踪玩家，接受 `Bullet` 伤害，并在死亡时掉落 `Pickup`。

`Bullet`（`Area2D`）负责直线移动、世界碰撞、寿命和命中后的销毁；当前伤害由敌人端固定处理。

`Pickup`（`Area2D`）读取 `PickupConfig`，玩家接触后调用 `Player.apply_pickup()`。

`Coin`（`Area2D`）是独立的金币实体，使用 Pickup 物理层检测玩家接触。`Enemy` 在统一死亡入口实例化金币，`Coin` 调用 `Player.add_coins()`，`Game` 通过玩家信号更新 HUD。金币脚本保留磁吸目标接口，但当前不执行磁吸运动。

## 物理层

项目已定义 World、Player、EnemyBody、EnemySensor、Bullet、Pickup、Explosion 七个 2D 物理层。脚本通过碰撞层/掩码区分世界阻挡、敌人感知、子弹命中和爆炸查询。

## Main Menu Startup Flow

`project.godot` uses `res://scene/main_menu.tscn` as the entry scene. The independent `MainMenu` Control scene handles title and button interactions, then changes to the existing `Game` scene. Game remains responsible for combat, HUD, pickups, and coins.

## Round and Shop Flow

`Game` now represents one timed combat round. When its existing countdown reaches zero, it saves the current Player coin amount to `GameSession` and changes to the independent `scene/shop.tscn`. Shop displays the current round and coins, supports relic purchases, then increments the round and starts a new Game scene. `GameSession` stores `current_round`, `current_coins`, and `owned_relics` for the current run, and owns the atomic relic-purchase rule so duplicate or underfunded purchases cannot deduct coins.

## Character Data and Selection

Phase 2 adds `CharacterConfig` Resources for Gunslinger, Scout, and Guardian.
MainMenu resets the run and opens `scene/character_select.tscn`; the selected
character ID is stored in `GameSession` before the first Game scene. At the
start of each round, `GameSession.resolve_character_stats()` starts from the
selected character's base values and applies owned relic bonuses once. Player
receives a copy of those resolved values, including the supported pickup-range
Area2D size, while the existing movement and shooting orchestration remains in
Player.

## Independent Weapon System

Phase 3 adds `WeaponConfig` Resources and `WeaponSystem`. Player forwards aim
and spawn validation to the system, which creates configured Bullet instances;
Bullet owns projectile speed, range, damage, and piercing for that shot.

Phase 4 adds `WeaponSynergyConfig` and a pure resolver over equipped weapon
tags. Active synergy IDs are derived for UI feedback and never recursively
written back into base weapon resources.
## Relic System

Relic Resources define display data and effect values. `GameSession.owned_relics` stores IDs and owns atomic coin/relic transactions for the current run; Shop owns purchase UI, while Game recalculates relic effects from Player base attributes at each new round.

Additional relic effects continue to use the existing Resource `EffectType` enum. Game applies movement speed, invincibility duration, and bullet spawn distance from each new Player's base attributes.

## Future Expansion Roadmap

The following systems are planned and are not implemented yet. They should be introduced incrementally, preserving the current scene flow and keeping combat responsibilities separated.

- `RunSession`/`GameSession` remains the owner of current-run state such as round, coins, owned relics, selected character, weapons, and future boss progress. It must not become a combat event bus.
- `Game` remains the single-round combat scene. Boss encounters, wave rules, and round modifiers should be supplied as data/configuration rather than embedded in Player, Enemy, or Shop.
- Character definitions should use Resources for base attributes, starting weapon, and passive traits. Player should apply a selected character's resolved stats once when a round starts.
- Weapons should be independent data-driven Resources/scenes. A weapon owns fire interval, damage, projectile pattern, cooldown, and upgrade data; Player owns input/orchestration rather than one hard-coded weapon implementation.
- Weapon synergies should be represented by data rules checked when the run's weapon set changes. They should grant resolved bonuses without repeatedly mutating already-resolved stats.
- Shop should remain an independent scene that presents weapons, relics, character upgrades, and later reroll/lock options. Purchase rules should use the existing current-run currency boundary.

## Boss ownership

`BossConfig` stores boss-only tuning. `Boss` owns phase and attack timing;
`Game` is responsible for spawning and transition decisions, while
`GameSession` remains the owner of temporary reward state.

## Phase 6 progression ownership

`GameSession` stores equipped weapons, temporary upgrade levels, and reroll
count for the current run. `Shop` owns offer presentation and calls atomic
transaction methods; `WeaponConfig` remains immutable source data.

Phase 7 keeps presentation in `Game` HUD only: Boss status is derived from the
runtime instance and does not add state ownership or persistence.
