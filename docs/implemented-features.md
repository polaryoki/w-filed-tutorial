# 已实现功能

- Godot 4.7 主场景、地图 TileMap 和世界边界。
- 玩家 WASD 八方向移动、方向键射击和朝向动画。
- 子弹实例化、直线移动、世界阻挡和生命周期销毁。
- 四类敌人配置资源、随机刷怪、刷怪上限和随关卡时间缩短刷怪间隔。
- 敌人追踪玩家、接触持续伤害、受击闪烁。
- 普通死亡动画和自爆敌人的爆炸伤害/动画流程。
- 玩家生命、无敌闪烁、死亡状态与胜负结算窗口。
- 移速、射速、武装和螺旋弹道道具 Buff。
- 敌人死亡后的加权道具掉落、道具寿命和过期闪烁。
- 背景音乐、射击、受击、死亡、爆炸、拾取等音效资源。
- HUD 生命显示和关卡倒计时条。
- 敌人按配置掉落金币，掉落位置带轻微随机偏移。
- 玩家接触自动拾取金币，金币数量通过 `Player` 接口和信号维护。
- HUD 显示当前金币数量。
- `Coin.set_magnet_target()` 和 `clear_magnet_target()` 已预留未来磁吸接口，当前不执行磁吸。

## Main Menu

- Added an independent `scene/main_menu.tscn` startup scene.
- Added title, Start Game, Settings placeholder, and Quit buttons.
- Start Game resets the run and opens the character selection scene before combat.

## Character Data and Selection

- Added `CharacterConfig` and three Resources: Gunslinger, Scout, and Guardian.
- Added `scene/character_select.tscn`; selection is validated and stored by
  `GameSession.selected_character_id`.
- Added per-round cached character-stat resolution with explicit clamps and
  rounding. Re-resolving a round does not compound relic effects.
- Player now applies supported resolved attributes and exposes the data-only
  damage/projectile/luck/armor/critical fields for the future weapon system.
- Added a dedicated pickup-range Area2D while preserving body-contact pickup
  and coin collection.

## Independent Weapon System

- Added `WeaponConfig` and a basic starter weapon Resource.
- Added `WeaponSystem` projectile spawning with configurable spread, speed,
  damage, range, and piercing.
- Player now delegates bullet construction while retaining input and movement.

## Round and Shop Flow

- Added `GameSession` Autoload with `current_round`, `current_coins`, and `owned_relics` current-run state.
- Game countdown completion transitions once to independent `scene/shop.tscn`.
- Shop displays the current round, current coins, and available relic offers.
- Continue advances the round and starts Game again; player death returns to MainMenu.
- Existing Player coin acquisition, Coin pickup, Pickup behavior, and HUD update logic remain unchanged.
## Relics

- Added Resource-defined Lucky Starting Gold, Rapid Chamber, and Reinforced Charm relics.
- GameSession stores owned relic IDs for the current run.
- Shop displays up to three non-owned relics, supports fixed-in-view purchases, coin deduction, and purchased states.
- Game applies owned relic effects from base Player attributes on each new round.
- Added Swift Boots, Iron Will, and Long Barrel relic Resources and per-round effects.
- Added `GameSession.try_purchase_relic()` as the single atomic relic purchase boundary; duplicate and underfunded purchase attempts do not change run state.
- Added `tests/phase1_smoke.gd`, a headless smoke script covering GameSession reset/purchase invariants and required scene loading.

## Scope Boundary

Boss battles, selectable characters, multi-attribute character progression, independent weapons, weapon synergies, rerolls, and permanent progression are planned systems only. They are not implemented in the current build.
