# Phase 10 Tasks: Real Multi-Weapon Loadout

以下切片仅供审核后实现；本轮不执行。

## Task 1 — Loadout 与交易契约

- 修改文件：`scene/game_session.gd`，必要时 `resourse/weapon/weapon_config.gd`。
- 实现内容：三槽位、有序去重 loadout；ID/起始武器校验；每武器等级；购买、升级、reset 原子方法。
- 前置条件：Phase 9 DONE；Phase 10 proposal/design 审核通过。
- 验收方式：smoke 覆盖重复、未知、满槽、余额不足、负价格、未装备升级、reset。
- 风险：破坏 Phase 6 交易兼容或误把静态 `upgrade_level` 当 Run 状态。

## Task 2 — WeaponConfig 运行时解析契约

- 修改文件：`resourse/weapon/weapon_config.gd` 及少量 `.tres` 数据（仅经审核字段）。
- 实现内容：每级 damage/interval、等级上限与解析边界；返回副本且不变异 Resource。
- 前置条件：Task 1 的等级契约。
- 验收方式：资源加载、等级数值和 immutability smoke。
- 风险：引入超过 Phase 10 的稀有度/合成字段。

## Task 3 — 独立多武器运行时

- 修改文件：`scene/weapon_system.gd`、`scene/player.gd`。
- 实现内容：runtime entries、独立 cooldown、共享 aim/spawn callback、逐武器 Bullet stats；保留必要的单武器兼容入口。
- 前置条件：Tasks 1-2。
- 验收方式：两把武器不同节奏同时发射；生成失败不阻塞；Bullet 使用正确 stats/weapon identity。
- 风险：首发时机、shooting timer、spiral 和拾取 Buff 回归。

## Task 4 — Character / Relic / XP 修正接线

- 修改文件：`scene/game_session.gd`、`scene/player.gd`，必要时 `scene/game.gd`。
- 实现内容：把现有攻击属性修正应用到每个 runtime entry；遵守已批准的非递归顺序。
- 前置条件：Task 3；stacking order 已批准。
- 验收方式：重复解析不叠加；升级/拾取即时生效；WeaponConfig 不变。
- 风险：健康值重置、旧 damage API 残留、暂停期间刷新错误。

## Task 5 — Shop 展示与事务接线

- 修改文件：`scene/shop.gd`、`scene/shop.tscn`，必要时 `scene/game_session.gd`。
- 实现内容：未装备购买、已装备等级/升级、满槽提示、交易后刷新；保留 relic/reroll/continue。
- 前置条件：Task 1；不得引入 Phase 11 inventory/combining。
- 验收方式：integration 覆盖购买、升级、重复、满槽、余额不足和金币显示。
- 风险：控件遮挡既有 UI 或重复信号连接。

## Task 6 — 回归验证与文档收口

- 修改文件：实现阶段才允许新增 `tests/phase10_*`；更新共享状态文档。
- 实现内容：最小 runtime/integration 覆盖；运行 Phase 1-10 全套；完成后才标记 DONE。
- 前置条件：Tasks 1-5 全部通过。
- 验收方式：兼容 headless 环境全绿，diff 无 Wave/Boss/永久存档/Phase 11 改动。
- 风险：测试时序、生成 `.uid` 噪音、误记规划为实现完成。
