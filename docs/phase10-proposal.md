# Phase 10 Proposal: Real Multi-Weapon Loadout

## 背景

Phase 1-9 已建立稳定的 MainMenu -> CharacterSelect -> Game -> Shop -> Game
本局循环、Character/Relic/XP/Boss/WaveDirector 边界和 Phase 9 runtime 回归基线。
Phase 3 的 WeaponSystem 已将子弹配置从 Player 中分离，Phase 6 又记录了
`equipped_weapon_ids` 与升级字典；但这些状态尚未形成真正的多武器运行时。

## 当前问题

- `GameSession.equipped_weapon_ids` 在 Phase 9 基线中只是可追加的 ID 列表，未定义槽位上限、顺序语义、未知 ID/重复 ID 的拒绝规则。
- Player 只有一个 `ShootingTimer`，射击入口最终只为一个 WeaponConfig 调用 `WeaponSystem.fire()`。
- WeaponSystem 没有每把武器的运行时实例、独立冷却或独立解析属性。
- WeaponConfig 的 `upgrade_level` 是静态资源字段，不能代表某个 Run 中某一把武器的升级状态。
- Shop 缺少“新武器”和“已装备武器升级”的并列展示与容量反馈。

## Phase 10 目标

1. 一个 Run 最多装备 3 把武器，顺序稳定且初始武器不可移除。
2. 每把已装备武器拥有独立的运行时冷却、弹道配置和升级等级。
3. GameSession 是本局 loadout、每武器等级和买卖原子事务的唯一所有者。
4. WeaponConfig 继续是不可变静态配置；升级只写入 GameSession 并解析为运行时副本。
5. Shop 同时展示可购买的新武器和已装备武器升级，并正确处理金币不足、重复购买和满槽位。
6. Player 继续负责输入、共享瞄准方向、生成点校验和临时拾取效果；WeaponSystem 负责多武器射击。
7. 保持 Character、Relic、XP、WaveDirector、Boss、结算与 Shop 场景流程兼容。

## 非目标

- 不做永久存档、跨 Run 武器解锁、稀有度库存生成、锁定、合成/融合或 Phase 11 Shop 重构。
- 不新增敌人行为、Boss/Wave 规则、Projectile 碰撞模型或新的升级系统。
- 本轮只设计，不实现或修改任何 gameplay/test 代码。

## 用户体验

新 Run 从角色的 starting weapon 开始。Shop 在有空槽时列出未装备武器及购买价格；已装备武器显示名称、当前等级和升级价格。购买或升级成功后金币、列表和等级立即刷新；失败操作显示原因且不扣金币。进入下一回合后，所有已购武器按各自节奏朝玩家当前瞄准方向射击。

## 风险

- 从单计时器迁移到多计时器可能改变首发时机、射击音效和拾取武装 Buff。
- Character/Relic/XP 的攻击速度、伤害和 projectile count 需要明确作用于每把武器的顺序。
- Shop 动态 UI 可能与现有固定布局冲突。
- 无效 loadout 数据可能导致空配置、重复武器或槽位溢出。

## 验收标准

- 新 Run 恢复为 `[basic]`、等级字典只含 Basic Lv1，容量为 3。
- 两把及以上武器可独立倒计时；一把因冷却或生成点阻挡不能射击不阻塞其他武器。
- 每个 Bullet 使用所属武器的 damage、fire interval、projectile count、spread、speed、range、piercing 和 Run 等级解析值；WeaponConfig 资源不被修改。
- 购买、重复购买、未知 ID、满槽位、升级未装备武器、负价格和金币不足均为原子 no-op。
- reset_run 清除额外武器及所有武器等级，并保留既有角色/遗物/XP reset 语义。
- Phase 1-9 smoke/integration 与 Phase 10 focused runtime 检查保持通过。
