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

Claude Code 使用 **Agent 工具** 派生子 Agent。与 Cursor 不同，Claude Code 没有独立的 Agent 定义文件目录——子 Agent 的完整指令直接注入到 Agent 工具的 `prompt` 参数中。

**调度模式**：编排器先读取共享 `.agents/agents/<agent>.body.md`，将其内容作为 Agent prompt 的一部分注入，确保子 Agent 获得完整指令。

### Agent 调度语法

```json
Agent({
  subagent_type: "general-purpose",
  model: "<opus|sonnet|haiku>",
  description: "<当前阶段简短描述>",
  prompt: "<完整 Agent 指令 + 上下文>"
})
```

### Agent body 文件与模型映射

| 阶段 | body 文件 | Claude Code 模型 |
|------|----------|-----------------|
| CREATE | `.agents/agents/create-agent.body.md` | `sonnet` |
| GATE_REVIEW | `.agents/agents/gate-review-agent.body.md` | `sonnet` |
| APPLY | `.agents/agents/apply-agent.body.md` | `opus` |
| CODE_REVIEW | `.agents/agents/code-review-agent.body.md` | `opus` |
| TEST | `.agents/agents/test-agent.body.md` | `haiku` |
| VERIFY | `.agents/agents/verify-agent.body.md` | `opus` |
| SYNC | `.agents/agents/sync-agent.body.md` | `sonnet` |
| ARCHIVE | `.agents/agents/archive-agent.body.md` | `sonnet` |

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

1. 查 `.agents/workflow/state-machine.yaml` 中 `agent_body_map` 获取当前阶段的 body 文件路径
2. 读取 body 文件完整内容
3. 查找上方映射表获取对应的 Claude Code 模型
4. 组装 prompt（body + 上下文）
5. 使用 Claude Code Agent 工具调度

### APPLY 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  description: "代码实现: add-dark-mode",
  prompt: "## Agent 指令\n\n<.agents/agents/apply-agent.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 闸门审查结论: openspec/changes/add-dark-mode/session/GATE-03_gate_review.md\n\n## 执行要求\n执行上述 Agent 指令中的所有步骤，产出对应文档。"
})
```

### CODE_REVIEW 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  description: "代码审查: add-dark-mode",
  prompt: "## Agent 指令\n\n<.agents/agents/code-review-agent.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 开发记录: openspec/changes/add-dark-mode/session/DEV-04_development.md\n\n## 执行要求\n执行上述 Agent 指令中的所有步骤，产出对应文档。"
})
```

### TEST 阶段调度示例

```json
Agent({
  subagent_type: "general-purpose",
  model: "haiku",
  description: "测试验证: add-dark-mode",
  prompt: "## Agent 指令\n\n<.agents/agents/test-agent.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n- Change Name: add-dark-mode\n- 项目看板: openspec/changes/add-dark-mode/session/project-board.yaml\n- 开发记录: openspec/changes/add-dark-mode/session/DEV-04_development.md\n- 代码审查: openspec/changes/add-dark-mode/session/CR-05_code_review.md\n\n## 执行要求\n执行上述 Agent 指令中的所有步骤，产出对应文档。"
})
```

## 与其他平台的差异

| 差异点 | Claude Code | Cursor |
|--------|------------|--------|
| 调度工具 | `Agent` | `Task` |
| Agent 类型 | `subagent_type: "general-purpose"` | `subagent_type: "agent-ref"` |
| Agent 指令 | prompt 内联注入完整 body | body 文件 + prompt 上下文 |
| 模型选择 | Agent 工具 `model` 参数 | Agent frontmatter `model` 字段 |
| 权限控制 | prompt 指令约束 | frontmatter `readonly` 字段 |
| Agent 定义文件 | 无（指令在 body 文件中） | `.cursor/agents/<agent-ref>.md` |
