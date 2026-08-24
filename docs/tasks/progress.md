# Progress

## Current Status

Phase 1 代码与静态检查完成；已加入可重复的 headless smoke script。引擎运行验证因当前环境未找到 Godot 可执行文件而阻塞。

## Tasks

- [x] Phase 1 — 稳定现有回合系统（静态检查与原子遗物购买完成）
- [ ] Phase 1 — Godot headless/runtime 验证（阻塞：未找到 godot 命令）
- [ ] Phase 2 — 角色数据与多属性系统

## Commands Run

- `rg --files`
- `rg -n "change_scene|reset_run|current_coins|confirmed|_complete_round|_show_result" scene`
- `godot --headless --path . --editor --quit`（失败：命令不存在）
- `godot --headless --path . --script res://tests/phase1_smoke.gd`（待 Godot 4.7 可执行文件可用后运行）

## Decisions

- 保持现有场景流和本局金币边界，不在 Phase 1 引入新玩法。
- 遗物购买收敛到 `GameSession.try_purchase_relic()`，保证扣款和所有权变更不可部分完成。

## Blockers

- 需要安装或提供 Godot 4.7 命令行可执行文件，才能完成 headless 检查和 runtime smoke test。

## Next Steps

- 在具备 Godot 4.7 的环境补跑 Phase 1 验证。
- 验证通过后再开始 Phase 2 设计与实现。
