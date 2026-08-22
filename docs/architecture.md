# 项目架构

## 技术与入口

- 引擎：Godot 4.7，Forward Plus。
- 主场景：`res://scene/game.tscn`，由 `project.godot` 的 `run/main_scene` 指定。
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

`Game` now represents one timed combat round. When its existing countdown reaches zero, it saves the current Player coin amount to the minimal `GameSession` Autoload and changes to the independent `scene/shop.tscn`. Shop displays the current round and coins, then increments the round and starts a new Game scene. Player death returns to MainMenu instead of Shop. GameSession only stores `current_round` and `current_coins` for this scene transition.
