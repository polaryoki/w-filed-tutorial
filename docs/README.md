# 项目文档

这些文档是本 Godot 项目的持久化上下文，记录当前架构、机制、已实现能力和后续计划。

## 使用约定

在修改功能、场景或资源前，先读取本目录相关文档；完成修改后同步更新文档，保持记录与代码一致。

- [项目架构](architecture.md)
- [游戏机制](game-mechanics.md)
- [已实现功能](implemented-features.md)
- [待开发功能](todo.md)

本文档基线依据当前仓库只读检查建立，未改变运行时代码。

## Main Menu Update

The project now starts at `res://scene/main_menu.tscn`. The menu routes the Start Game action to `res://scene/game.tscn`; Settings is a placeholder and Quit exits normally.

## Continue development

The durable restart point is [`continuation.md`](continuation.md). It records
the verified Phase 1-8 baseline, runtime environment, required reading order,
guardrails, and the first action for the next terminal session.

Planning documents:

- [`development-roadmap.md`](development-roadmap.md): Phase 9-16 gameplay plan.
- [`visual-direction.md`](visual-direction.md): original industrial tactical
  presentation and third-party originality boundaries.
- [`phase9-proposal.md`](phase9-proposal.md): next-phase scope and acceptance.
- [`phase9-design.md`](phase9-design.md): proposed WaveDirector architecture.
- [`tasks/phase9-wave-director.md`](tasks/phase9-wave-director.md): executable
  Phase 9 task breakdown.
- [`phase9-prompt.md`](phase9-prompt.md): ready-to-use next-session control
  prompt.
