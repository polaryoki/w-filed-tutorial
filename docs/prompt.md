# 完整游戏实现提示词

下面的提示词用于驱动 Codex、Claude Code、Cursor 等编码代理。建议按 Phase 1 到 Phase 7 顺序执行；每次只执行一个阶段，完成验证后再进入下一阶段。

## 总控提示词

```text
你是本 Godot 4.7（Forward Plus）项目的主工程代理，目标是把现有的俯视角生存射击原型扩展为可完整游玩的单机游戏。

开始前必须读取：
- docs/README.md
- docs/architecture.md
- docs/game-mechanics.md
- docs/implemented-features.md
- docs/todo.md
- docs/prompt.md

工作规则：
1. 先检查当前代码、场景、Resource、Autoload 和 project.godot，确认文档与实现是否一致。
2. 按指定 Phase 顺序执行；一次只实现一个阶段，不跨阶段偷偷加入长期方向。
3. 保留现有 MainMenu -> Game -> Shop -> Game 的流程、当前回合金币边界、Player/Coin/Pickup/Enemy/Bullet 的兼容行为。
4. 所有可调数值优先放入 Resource/config 或集中配置，不把平衡数字散落在脚本中。
5. 新系统必须有明确的所有权：GameSession 只保存本局状态，Game 管理单回合，Player 管理输入和移动，Weapon 管理武器射击，Enemy/Boss 管理自身行为，Shop 只负责展示和购买。
6. 每个阶段先写或更新设计与任务文档，再修改代码；不要进行无关重构，不覆盖用户已有改动。
7. 每个阶段完成后运行 Godot 无头检查/项目测试（若项目没有测试则补充最小可重复 smoke test），检查 git diff，并更新 docs/implemented-features.md、docs/architecture.md、docs/game-mechanics.md 和进度记录。
8. 需求、数据契约、资源格式、外部依赖或破坏性改动存在歧义时，暂停并提问，不要自行猜测。

最终报告必须包含：实现内容、修改文件、验证命令及结果、已知风险、下一阶段建议。
```

## Phase 1：稳定现有流程

```text
读取 docs 全部文件以及当前 MainMenu、Game、Shop、GameSession、Player、Coin、Enemy、Pickup 相关脚本和场景。
目标：不改变玩法的前提下修复并验证现有流程。
- 统一 res://scene 与 res://Scene 的路径大小写。
- 验证 GameSession.reset、金币在 Game/Shop 间交接、遗物购买、跨回合效果重算。
- 确保胜利只触发一次，死亡只触发一次，死亡不进入 Shop，暂停/重开/结算界面可重复运行。
- 为关键流程增加 focused tests 或可重复 smoke test。
完成后更新文档并报告所有失败场景。
```

## Phase 2：角色数据与多属性

```text
在不破坏现有 Player 移动和射击的前提下，实现数据驱动角色系统。
- 新建 CharacterConfig Resource：id、名称、描述、基础生命、移速、射击间隔、伤害、子弹数、拾取范围、幸运、护甲、暴击率、初始武器/被动。
- 增加角色选择界面，并把选择写入 GameSession；开始新回合时一次性解析“角色基础值 + 本局遗物/升级”。
- 明确属性叠加顺序、上限、四舍五入和 HUD 显示规则，禁止跨回合重复叠加。
- 至少提供 3 个可区分角色及资源实例。
- 增加解析逻辑测试、角色选择流程测试和运行时 smoke test。
```

## Phase 3：独立武器系统

```text
实现独立、可配置、可多装备的武器系统。
- 新建 WeaponConfig Resource：id、伤害、冷却、子弹数、散射角、速度、射程、穿透、标签、升级等级/费用。
- Weapon 场景或脚本负责生成 Bullet、计算弹道和冷却；Player 只负责输入编排、瞄准方向和装备列表。
- 支持多个装备武器及每局临时升级；保留现有 Bullet 碰撞、生命周期和伤害兼容性，必要扩展必须最小化。
- 将现有硬编码射击迁移为默认武器资源，并提供至少 3 把武器。
- 测试冷却、散射、多个武器独立计时、穿透和资源配置加载。
```

## Phase 4：武器协同

```text
实现数据驱动的武器协同系统。
- 定义武器标签和 SynergyConfig：所需标签/武器集合、激活数量、加成、展示文本。
- 根据当前装备集合解析协同，只对已解析武器属性应用一次，不允许递归或跨回合累加。
- 在 Shop 和 HUD 显示激活/未激活协同及其效果。
- 装备、购买、升级、移除武器后重新计算并覆盖旧结果。
- 增加边界测试：重复标签、多个协同同时激活、跨回合重算、缺少资源。
```

## Phase 5：Boss 战

```text
加入独立于普通 Enemy 的 Boss 回合系统。
- 新建 BossConfig Resource：生命、阶段、攻击模式、移动、攻击间隔、预警、奖励、生成规则和竞技场限制。
- 在配置的回合或波次阈值生成 Boss；Game/回合流程拥有 Boss 进度，Shop/MainMenu 不承载战斗逻辑。
- 实现至少一个拥有 2 个阶段、明确 telegraph、可识别攻击模式的 Boss。
- 定义 Boss 击败、玩家死亡、超时、奖励发放和进入 Shop 的唯一状态转换。
- 奖励进入本局 GameSession，不实现未批准的永久存档。
- 测试阶段转换、攻击冷却、奖励只发放一次及重复进入场景。
```

## Phase 6：扩展商店与本局成长

```text
扩展 Shop，但保持其只负责展示和交易。
- 支持遗物、武器、武器升级、角色属性升级、重掷和可选锁定。
- 定义库存生成、稀有度/权重、价格、重掷费用、锁定规则和购买失败反馈。
- 所有临时成长写入 GameSession，并在新 Game 回合开始时通过统一解析器应用。
- 加入 Boss 奖励和回合里程碑；金币仍只在本局有效。
- 为购买、重掷、锁定、金币不足、重复购买和场景返回编写测试。
```

## Phase 7：平衡与表现

```text
在功能稳定后进行数据和表现收尾。
- 集中整理角色/武器/遗物/Boss 的平衡表和难度曲线，避免脚本内散落常量。
- 完善 HUD：生命、金币、回合计时、击杀数、武器、协同、Boss 阶段和 Buff 剩余时间。
- 增加 Boss 预警、受击/死亡/胜利反馈、音效和像素风图标；缺少美术资源时使用可替换占位资源。
- 编写自动化 smoke test、可重复回合验证和基础性能检查。
- 最后运行完整验证清单，检查无未引用资源、路径大小写错误、调试输出和意外永久存档。
```

## 每阶段结束时追加的验证提示词

```text
请对刚完成的阶段执行收尾审查：读取相关 diff 和文档，运行 Godot 项目检查、该阶段测试及一次可重复运行 smoke test；检查场景切换、信号连接、Resource 路径、空引用、重复结算和跨回合状态污染。只修复本阶段范围内的问题。更新 docs/implemented-features.md、docs/architecture.md、docs/game-mechanics.md 和进度记录，并按“通过项/失败项/风险/下一步”格式报告。
```
