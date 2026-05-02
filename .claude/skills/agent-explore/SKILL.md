---
name: agent-explore
description: Claude Code 平台探索模式立场定义。核心逻辑继承 .agents/skills/agent-explore/SKILL.md（共享核心）。
license: MIT
compatibility: Claude Code CLI
metadata:
  author: openspec-agents
  version: "1.0"
  platform: claude-code
---

# 探索模式 - Claude Code 适配层

> **核心探索逻辑**：参见 `.agents/skills/agent-explore/SKILL.md`（共享核心）。
> 本文件仅说明 Claude Code 特有的执行方式。

## Claude Code 平台执行方式

**EXPLORE 阶段由 MainOrchestrator 亲自执行，不使用 Agent 工具。**

编排器直接进入探索模式：
1. 参照 `.agents/skills/agent-explore/SKILL.md`（共享核心）中的执行步骤
2. 与用户实时对话，逐步澄清需求和方案
3. 产出 REQ-01_requirement_analysis.md 和 DES-02_solution_design.md
4. 用户确认后退出探索模式，回归纯调度角色
