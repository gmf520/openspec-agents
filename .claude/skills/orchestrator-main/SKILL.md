---
name: orchestrator-main
description: Claude Code 平台的主调度智能体。核心逻辑继承 .agents/skills/orchestrator-main/SKILL.md（共享核心），本文件仅定义 Claude Code 特有的 Agent 工具调度方式。
license: MIT
compatibility: Claude Code CLI
metadata:
  author: openspec-agents
  version: "1.0"
  dependency: .agents/skills/orchestrator-main/SKILL.md
  platform: claude-code
---

# MainOrchestrator - Claude Code 适配层

> **核心编排逻辑**：参见 `.agents/skills/orchestrator-main/SKILL.md`（共享核心）。
> 本文件仅包含 Claude Code 平台特有的调度语法、模型映射和路径差异。

## Claude Code 平台调度机制

Claude Code 使用 **Agent 工具** 派生子 Agent。子 Agent 在 `.claude/agents/` 目录中以 YAML frontmatter 注册（name、description、tools、model）。Agent 指令体在 frontmatter 之后，由 Claude Code 原生 Agent 系统自动读取，无需编排器手动注入。

**调度模式**：编排器只传递任务上下文（change-name + 前一阶段产出路径），Agent 指令由注册文件提供。使用 `isolation: "worktree"` 和 `run_in_background: true` 确保子 Agent 在独立 CLI 子进程中执行。

### Agent 调度语法

```json
Agent({
  subagent_type: "general-purpose",
  model: "<opus|sonnet|haiku>",
  description: "<当前阶段简短描述>",
  isolation: "worktree",
  run_in_background: true,
  prompt: "## 当前任务上下文\n\n- Change Name: <change-name>\n- 项目看板: openspec/changes/<change-name>/session/project-board.yaml\n- 前一阶段产出: <artifacts>\n\n## 执行要求\n执行你在 .claude/agents/ 中注册的 Agent 定义中的所有步骤，产出对应文档。"
})
```

### Agent body 文件与模型映射

| 阶段 | 注册文件 | Claude Code 模型 |
|------|---------|-----------------|
| CREATE | `.claude/agents/create-agent.md` | `sonnet` |
| GATE_REVIEW | `.claude/agents/gate-review-agent.md` | `sonnet` |
| APPLY | `.claude/agents/apply-agent.md` | `opus` |
| CODE_REVIEW | `.claude/agents/code-review-agent.md` | `opus` |
| TEST | `.claude/agents/test-agent.md` | `haiku` |
| VERIFY | `.claude/agents/verify-agent.md` | `opus` |
| SYNC | `.claude/agents/sync-agent.md` | `sonnet` |
| ARCHIVE | `.claude/agents/archive-agent.md` | `sonnet` |

### 模型策略说明

- **opus**：代码生成、代码审查、最终验证——需要最强推理能力
- **sonnet**：文档生成、审查分析、同步归档——平衡性能与成本
- **haiku**：测试运行——轻量快速

### 脚本路径

Claude Code 适配层使用项目根 `scripts/` 目录下的共享脚本：

| 脚本 | 路径 |
|------|------|
| 编译检查 | `.agents/scripts/compile_check.ps1` |
| 闸门审查辅助 | `.agents/scripts/gate_review.ps1` |
| 测试运行 | `.agents/scripts/test_runner.ps1` |
| 完整验证 | `.agents/scripts/verify_all.ps1` |

## 调度步骤（CREATE 起）

1. 查 `.agents/workflow/state-machine.yaml` 中 `agent_body_map` 获取当前阶段的注册文件路径
2. 查找上方映射表获取对应的 Claude Code 模型
3. 组装上下文 prompt（只包含 change-name + 前一阶段产出路径，不含 Agent 指令）
4. 使用 Claude Code Agent 工具调度（Agent 指令由 `.claude/agents/` 注册文件提供）

### APPLY 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  description: "代码实现: add-dark-mode",
  isolation: "worktree",
  run_in_background: true,
  prompt: "## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 闸门审查结论: openspec/changes/add-dark-mode/session/GATE-03_gate_review.md\n\n## 执行要求\n执行你在 .claude/agents/apply-agent.md 中注册的 Agent 定义中的所有步骤，产出对应文档。"
})
```

### CODE_REVIEW 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  description: "代码审查: add-dark-mode",
  isolation: "worktree",
  run_in_background: true,
  prompt: "## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 开发记录: openspec/changes/add-dark-mode/session/DEV-04_development.md\n\n## 执行要求\n执行你在 .claude/agents/code-review-agent.md 中注册的 Agent 定义中的所有步骤，产出对应文档。"
})
```

### TEST 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "测试验证: add-dark-mode",
  isolation: "worktree",
  run_in_background: true,
  prompt: "## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 开发记录: openspec/changes/add-dark-mode/session/DEV-04_development.md\n- 代码审查: openspec/changes/add-dark-mode/session/CR-05_code_review.md\n\n## 执行要求\n执行你在 .claude/agents/test-agent.md 中注册的 Agent 定义中的所有步骤，产出对应文档。"
})
```

## 与其他平台的差异

| 差异点 | Claude Code | Cursor |
|--------|------------|--------|
| 调度工具 | `Agent` | `Task` |
| Agent 定义 | `.claude/agents/<agent>.md`（YAML frontmatter + 完整指令） | `.cursor/agents/<agent>.md`（YAML frontmatter + body 引用） |
| Agent 类型 | `subagent_type: "general-purpose"`，指令由注册文件提供 | `subagent_type: "agent-ref"`，指令由编排器注入 |
| Agent 指令 | YAML frontmatter 后的 body 内容（原生读取） | body 文件（编排器注入 Task prompt） |
| 模型选择 | YAML frontmatter `model` 字段 + Agent 工具 `model` 参数 | frontmatter `model` 字段 |
| 权限控制 | YAML frontmatter `tools` 字段 | frontmatter `readonly` 字段 |
| Agent 定义文件 | `.claude/agents/<agent>.md` | `.cursor/agents/<agent>.md` |
| 隔离执行 | `isolation: "worktree"`（独立 git worktree） | 无 |
| 异步执行 | `run_in_background: true`（独立 CLI 子进程） | 无 |
