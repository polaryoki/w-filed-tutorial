# Task: Phase 1 — 稳定现有回合系统

## Objective

验证并稳定 MainMenu -> Game -> Shop -> Game 的本局流程，确保 GameSession 重置、金币交接、遗物购买、胜负结算和跨回合遗物重算不会重复执行或污染状态。

## Input Docs

- docs/README.md
- docs/architecture.md
- docs/game-mechanics.md
- docs/implemented-features.md
- docs/todo.md
- docs/prompt.md

## Expected Files

- scene/game_session.gd
- scene/main_menu.gd
- scene/game.gd
- scene/shop.gd
- 相关 .tscn（仅在静态检查发现路径/信号问题时修改）
- docs/implemented-features.md
- docs/architecture.md
- docs/game-mechanics.md

## Checks

- [x] 静态确认 project.godot 的 main_scene 和 GameSession Autoload
- [x] 静态确认 MainMenu 开始游戏会 reset_run
- [x] 静态确认 Game 胜利只保存金币并进入 Shop
- [x] 静态确认玩家死亡不进入 Shop，结算后 reset_run 并返回 MainMenu
- [x] 静态确认 Shop 购买使用 GameSession 余额且不可重复购买
- [ ] Godot headless editor/import check（当前环境未找到 Godot 4.7 可执行文件，阻塞）
- [ ] Godot runtime smoke test：`godot --headless --path . --script res://tests/phase1_smoke.gd`（当前环境未找到 Godot 4.7 可执行文件，阻塞）

## Definition Of Done

- 状态所有权和场景转换与文档一致
- 遗物购买以单一原子交易完成；重复购买或金币不足不会污染状态
- 引擎可用时补跑 headless/import 与 runtime 检查
