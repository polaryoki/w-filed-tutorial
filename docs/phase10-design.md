# Phase 10 Design: Real Multi-Weapon Loadout

## 数据结构

- `GameSession.equipped_weapon_ids: Array[StringName]`：有序、去重、最多 3 个元素；第一个是不可移除的起始武器。
- `GameSession.weapon_upgrade_levels: Dictionary`：`StringName -> int`，缺省为 1；只保存 Run 状态。
- `GameSession.MAX_WEAPON_SLOTS = 3`：唯一容量常量，Shop 只读取。
- `WeaponConfig`：静态身份、弹道、标签和每级成长参数；`upgrade_level` 不作为 Run 状态来源。
- WeaponSystem runtime entry：`config`、`level`、解析后的 `stats`、`cooldown_left`，全部是运行时副本。

## GameSession 职责

提供配置查询、已装备配置快照、等级查询、购买、升级和 reset 语义。事务先完整校验已知 ID、重复、槽位、正价格、余额、所有权和等级上限，再一次性扣款和写入；失败不得部分修改。Synergy 只从 loadout 派生，不变异资源。

## Player 职责

继续读取输入/自动射击模式、计算共享 aim、维护现有拾取 Buff、播放射击音效并提供 bullet spawn raycast。回合开始把 GameSession 的配置与等级传给 WeaponSystem；Character/Relic/XP 的已解析攻击属性以 runtime modifiers 传入。Player 不保存第二份 loadout，也不维护每武器 cooldown。

## WeaponSystem 职责

维护 runtime entry 集合；setup 在回合开始创建副本，modifier 刷新只重算副本。每帧先分别减少 cooldown，再对可发射 entry 调用既有 Bullet 初始化。成功才重置该 entry 的 cooldown。WeaponSystem 不读 Shop、不扣金币、不改 WeaponConfig。

## Shop 职责

沿用现有固定价格和 reroll 边界，不引入库存生成。未装备武器行显示购买按钮；已装备武器行显示 `Lv.N` 与升级按钮；满槽位时禁用购买并显示容量提示。按钮只调用 GameSession 原子方法，成功后刷新金币、等级和列表。

## WeaponConfig 职责

继续作为不可变静态 Resource，保存 `id/display_name/damage/fire_interval/projectile_count/spread_degrees/projectile_speed/range/piercing/tags`。Phase 10 仅在确有需要时增加每级 damage、interval 和等级上限/定价字段；不保存当前 Run 等级、cooldown 或临时 Buff。

## 调用链

```text
GameSession loadout + levels
          -> Game round start -> Player.configure loadout
Input/spiral aim -> Player -> WeaponSystem.advance_and_fire
                                      | per-entry cooldown
                                      v
                                  Bullet -> Enemy/Boss
Shop button -> GameSession atomic transaction -> Shop refresh
```

当前 Phase 9 基线实际链为 `Input -> Player.ShootingTimer -> WeaponSystem.fire -> Bullet`；实现时只替换 cooldown 所有权，不改变 Player 输入、spawn callback 或 Bullet/Enemy/Boss 接口。

## 生命周期

- Run reset：从所选角色的合法 starting weapon 初始化；Phase 10 首版兼容默认 Basic，等级为 1，清空其余等级。
- Game ready：Game 解析 Character/Relic/XP；Player 读取 loadout 并创建 runtime entries。
- Combat：每帧独立推进 cooldown；SceneTree pause、结果和场景切换仍由既有流程控制。
- Shop：只改变 GameSession；下一回合重建 runtime 副本，不跨场景保存 cooldown。

## 升级机制

解析顺序固定为：WeaponConfig 基础 stats -> 该武器 Run level -> Character/Relic/XP runtime 修正 -> synergy 修正一次 -> 临时拾取 fire-rate/form 修正。Damage/projectile count 使用相对既有基础武器语义的 additive modifier；fire interval 使用乘数并 clamp。任何不同顺序必须先修改设计和测试。

## 多武器攻击机制

所有武器共享同一 aim 向量和 spawn-validation callback，但不共享 cooldown、stats 或等级。aim 为零时只推进 cooldown；单个 entry 生成失败不影响其他 entry。螺旋相位仍属于 Player。每帧最多让每个 entry 完成一次 volley，避免大 delta 产生无界补发。

## 边界情况

未知/重复 ID、空配置、满槽位、非正价格、余额不足、未装备升级、非法等级、Bullet 实例化失败、重复 setup 均须安全 no-op 或返回明确失败。删除武器、合成、随机库存和永久保存不在本阶段。

## Character / Relic 影响

Character 的 damage、projectile_count、fire_interval 作用于每个 runtime entry；starting weapon 只参与 Run 初始化。Rapid Chamber、Phase 8 Attack Speed 和临时 rapid buff 统一转换为 interval modifier；Long Barrel 仍由 Player 的共享 spawn distance 处理。其他字段不改变 loadout 所有权。

## Boss / Wave 影响

无需修改。Boss 继续读取 Bullet.damage，WaveDirector 继续只管理敌人节奏。Game 的死亡、胜利、Boss timeout、Shop transition 和 Phase 8 pause arbitration 保持原路径。

## 测试策略

- GameSession smoke：容量、顺序、reset、购买/升级事务和失败 no-op。
- WeaponSystem smoke：两把武器不同 interval、独立 cooldown、不同 projectile stats、Resource 不变。
- 场景 integration：共享 aim 下观察两种 weapon identity 的 Bullet，升级其中一把，验证另一把不受影响。
- 回归：Phase 1-9 全套 smoke/integration，重点覆盖 level-up pause、Boss、死亡和 Shop transition。
