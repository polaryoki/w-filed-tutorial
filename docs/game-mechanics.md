# 游戏机制

## 核心循环

玩家在封闭地图中移动并使用方向键射击；敌人从场景中的出生点持续生成并追踪玩家。关卡有倒计时，倒计时结束胜利，玩家生命归零失败。

## 玩家

- WASD 移动，方向键射击。
- `ShootingTimer` 限制射击间隔；普通模式发射单发子弹，螺旋模式按相位发射前后方向子弹。
- 受到伤害后进入短暂无敌并显示闪烁效果。
- 可拾取移速、射速和武装/螺旋弹道相关 Buff，Buff 到期恢复默认状态。

## 敌人

- `Game` 随机选择 `EnemyConfig` 和出生点生成敌人。
- 敌人按配置移动速度、生命和动画运行。
- 接触玩家造成周期伤害。
- 自爆型敌人在死亡动画阶段进行范围伤害，可伤害玩家和其他敌人。

## 攻击与死亡

玩家生成 `Bullet`；子弹进入敌人感知区域后调用 `Enemy.apply_damage(1)` 并销毁。敌人生命归零后禁用碰撞、尝试掉落道具、播放死亡/爆炸动画，动画结束销毁。玩家生命归零后停止移动和攻击，`Game` 显示失败对话框并暂停世界。

## 道具

敌人死亡按 `pickup_drop_chance` 从加权配置列表随机生成一个道具；道具可在寿命结束前闪烁，玩家接触后应用 Buff 并销毁。

## 金币

敌人死亡按 `EnemyConfig.coin_drop_chance` 判断是否掉落一个金币，面值由 `coin_value` 决定。金币生成在死亡位置附近，并加入约 ±4 像素的随机偏移。玩家接触金币后自动调用 `Player.add_coins()`，金币销毁，`coins_changed` 信号驱动 HUD 更新。当前金币仅在本局有效，不实现磁吸或跨关卡存档。

## Round and Shop

- Each `Game` instance is one combat round using the existing `stage_duration` / `stage_time_left` countdown.
- Surviving until the countdown reaches zero completes the round and opens the independent Shop scene.
- Shop displays the round, current coins, and up to three fixed-in-view relic offers; insufficient coins prevent purchase and successful purchases update the current-run state.
- Player death follows the failure path back to MainMenu and never enters Shop.
- Player remains the source of truth for coins; GameSession only temporarily carries current coins between Game and Shop during the current run.
## Relics

Relics are permanent passive effects for the current run only. Shop offers up to three randomly ordered, non-owned relics; insufficient coins prevent purchase and a purchased relic cannot be bought again. Lucky Starting Gold grants 2 coins at each new round, Rapid Chamber reduces the base fire interval by 10%, and Reinforced Charm adds 1 base maximum health. Effects are recalculated per round and do not stack repeatedly across rounds.

Swift Boots increases movement speed by 15%, Iron Will adds 0.25 seconds of invincibility after damage, and Long Barrel increases bullet spawn distance by 6. These effects persist for the current run and are recalculated from base Player attributes each round.
