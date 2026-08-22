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
- Start Game opens the existing Game scene; no combat or coin logic was changed.

## Round and Shop Flow

- Added `GameSession` Autoload with only `current_round` and `current_coins` state.
- Game countdown completion transitions once to independent `scene/shop.tscn`.
- Shop displays the current round, current coins, and a not-yet-available item placeholder.
- Continue advances the round and starts Game again; player death returns to MainMenu.
- Existing Player coin acquisition, Coin pickup, Pickup behavior, and HUD update logic remain unchanged.
