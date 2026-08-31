# Phase 11 Proposal: Shop Inventory and Weapon Combining

## 1. 背景

Phase 10 已完成并通过 runtime 验收：`GameSession` 拥有三槽位有序武器
loadout、每武器 Run 等级和原子购买/升级事务；`WeaponSystem` 使用独立 runtime
entry；WeaponConfig 保持不可变。当前 Shop 仍分别展示随机 relic 和完整 weapon
列表，inventory、lock 与递增 reroll 尚未形成统一的 Run 状态。

## 2. Phase 10 已有能力

- `GameSession` 是当前 Run 金币、武器 loadout、武器等级和 relic 所有权的所有者。
- 新武器购买、已装备武器升级和 relic 购买均有失败 no-op 边界。
- 武器最多三把，等级由 `MAX_WEAPON_LEVEL` 约束。
- Character/Relic/XP modifier、Shop 交易与多武器 runtime 已通过 Phase 10 验收。
- WeaponConfig 与 RelicData 是静态 Resource；运行时状态不得写回 Resource。

## 3. 目标

1. 每次 Shop 持有三个由 Weapon 与 Relic 混合组成的 offer。
2. 使用最小 rarity/weight 数据驱动候选抽取。
3. 单槽 offer 可锁定；reroll 只替换未锁定槽。
4. reroll 从 5 coins 起，每次成功后下一次价格增加 2，当前 Run 内累计。
5. 已拥有武器再次出现时，购买语义为该武器升一级。
6. 所有 inventory、lock、reroll 与购买变化由 GameSession 原子提交。
7. reset 后不保留上一 Run 的 offer、lock 或递增价格。

## 4. 非目标

- 不建立通用 Item 基类、Item inventory、stat sheet、正负属性或 stacking system。
- 不创建武器副本、背包、合成槽、拆解、配方或复杂融合 UI。
- 不修改 WeaponConfig 的 Phase 10 等级解析语义。
- 不重构 WeaponSystem、Player、WaveDirector 或 Boss，不增加战斗机制。
- 不做永久存档、meta progression 或跨 Run 解锁。
- 本规划轮不实现 gameplay 或测试代码。

## 5. 用户体验与 Shop flow

进入 Shop 时展示三个混合 offer、当前金币和当前 reroll 价格。每个槽显示类型、
名称、rarity、价格、武器当前/下一等级以及 lock 状态。玩家可独立切换 lock；
reroll 后锁定槽原位保留，其他槽重新抽取。购买成功后该槽立即补充一个新的合法
offer；若无候选则显示空槽。继续按钮保持现有 Shop -> Game 流程。

## 6. Weapon + Relic mixed inventory

Phase 11 中路线图的 `mixed weapon/item offers` 明确定义为 Weapon + Relic。
同一 inventory 内不允许出现相同 `offer_type + content_id`。已拥有 relic、满级武器
以及满武器槽时未拥有的武器不是合法候选。候选不足三个时允许空槽。

WeaponConfig 和 RelicData 当前没有 rarity/weight。实现阶段只为两者增加相同语义的
最小字段：展示用 rarity 和正数抽取 weight；不引入共同 Item 父类或 rarity 生态。

## 7. Duplicate Weapon -> Upgrade

未拥有武器 offer 使用现有购买语义并占用一个 loadout 槽；已拥有同 ID 武器 offer
使用现有升级语义，将等级增加且仅增加一级。达到 `MAX_WEAPON_LEVEL` 后不生成可购买
offer。重复武器不创建第二实例，也不改变 WeaponConfig。

## 8. Offer lock

lock 以 inventory slot 为单位。每槽独立保存 `locked`；锁定槽在 reroll 后保持
offer、位置和 locked 状态。购买成功后旧 offer 与 lock 一同移除，补充的新 offer
默认未锁定。空槽不可锁定。新 Run 清除所有 lock。

## 9. Reroll

当前价格为 `5 + 2 * shop_reroll_count`。成功 reroll 原子扣费、替换所有未锁定槽并
将 counter 加一；锁定槽不变。失败时金币、counter、inventory 和 lock 均不变化。
不设置 reroll 上限。三个槽均锁定时 reroll 是无意义操作，必须拒绝且不扣费。

## 10. Run 生命周期

inventory 首次进入 Shop 时按需生成，并在当前 Run 的场景切换间保存在 GameSession。
购买和 reroll 原地更新该 inventory。`reset_run()` 清除 inventory、lock、reroll
counter 与相关临时状态，使当前价格恢复为 5；下一次 Shop 重新生成。

## 11. 原子事务要求

购买、reroll 和 lock 都先验证 slot、offer 身份、Resource、价格、余额、所有权、
loadout 容量和等级上限，再一次性提交。任何失败不得产生部分金币、等级、所有权、
inventory、lock 或 counter 更新。Shop 不自行扣款或写入 Run 状态。

## 12. Resource immutable 要求

Resource 只提供静态 ID、显示数据、rarity、weight、价格或武器配置。inventory 保存
ID 和 runtime snapshot；`locked`、当前价格、武器等级与所有权只属于 GameSession。
抽取、购买、补槽、reroll 和 reset 不得修改 WeaponConfig 或 RelicData 实例。

## 13. 与 Phase 10 的兼容边界

保留三槽位 loadout、`MAX_WEAPON_LEVEL`、逐武器等级、modifier resolution、独立
runtime entry 和现有 Shop transaction 行为。Phase 11 只在 Shop 选择与事务入口上
组合已有购买/升级语义，不改变 combat stat 顺序或 WeaponConfig 等级算法。

## 14. 与 Phase 12 的边界

Phase 12 才能定义通用 Item、正负属性、tag/stack 规则、stat sheet 和完整 rarity
生态。Phase 11 的 rarity/weight 只服务 Weapon/Relic Shop 抽取。更复杂的 weapon
combining 需要独立设计，不由本阶段标题隐含授权。

## 15. 风险

- 随机测试若不注入 RNG 会不稳定。
- Shop 当前同时维护 relic/weapon 展示副本，迁移时可能产生双重状态所有权。
- 购买后补槽若未排除现有 offer，可能在同一 inventory 产生重复。
- 原子事务若先扣费再发现满槽、满级或无效 offer，会造成部分更新。
- 老测试依赖固定 weapon/relic 列表，需区分契约迁移与 Phase 10 回退。

## 16. 验收标准

- GameSession 可用确定性 RNG 生成三个无重复的 Weapon/Relic 混合槽。
- rarity/weight 合法且 Resource 在所有 Shop 操作后保持不变。
- lock、购买补槽和递增 reroll 符合上述规则。
- 重复 weapon 只提升一级；满级、满槽、余额不足和非法输入均原子失败。
- reset/reload 后无旧 offer/lock，counter 为 0，reroll price 为 5。
- Shop 仅渲染 GameSession snapshot，并通过 GameSession 执行操作。
- Phase 1-10 必要 smoke/integration 保持兼容；没有 Phase 12 或永久状态代码。

