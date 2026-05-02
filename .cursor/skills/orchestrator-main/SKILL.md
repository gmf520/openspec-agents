---
name: orchestrator-main
description: Cursor 平台的主调度智能体。核心逻辑继承 .agents/skills/orchestrator-main/SKILL.md，本文件仅定义 Cursor 特有的 Task 工具调度方式。
license: MIT
compatibility: Cursor IDE
metadata:
  author: openspec-agents
  version: "2.0"
  dependency: .agents/skills/orchestrator-main/SKILL.md
  platform: cursor
---

# MainOrchestrator - Cursor 适配层

> **核心编排逻辑**：参见 `.agents/skills/orchestrator-main/SKILL.md`（共享核心）。
> 本文件仅包含 Cursor 平台特有的调度语法、模型映射和路径差异。

## Cursor 平台调度机制

Cursor 使用 **Task 工具** 派生子 Agent。子 Agent 定义文件在 `.cursor/agents/<agent-ref>.md`，其 frontmatter（name / model / readonly）由 Cursor 自动读取。

**调度模式**：编排器先读取共享 `agents/<agent>.body.md`，将其内容注入到 Task prompt 中，确保子 Agent 获得完整指令。

### Task 调度语法

```yaml
Task:
  subagent_type: "<agent-ref>"            # 对应 .cursor/agents/<agent-ref>.md
  description: "<当前阶段简短描述>"
  prompt: |
    ## Agent 指令

    <从 ../../.agents/agents/<agent>.body.md 读取的完整内容>

    ---

    ## 当前任务上下文

    - Change Name: <change-name>
    - 项目看板: openspec/changes/<change-name>/session/project-board.yaml
    - 前一阶段产出: <artifacts>

    ## 执行要求
    执行上述 Agent 指令中的所有步骤，产出对应文档。
```

### Agent body 文件映射

| 阶段 | agent_ref (subagent_type) | body 文件 | Cursor Agent 文件 |
|------|--------------------------|-----------|-------------------|
| CREATE | `create-agent` | `../../.agents/agents/create-agent.body.md` | `.cursor/agents/create-agent.md` |
| GATE_REVIEW | `gate-review-agent` | `../../.agents/agents/gate-review-agent.body.md` | `.cursor/agents/gate-review-agent.md` |
| APPLY | `apply-agent` | `../../.agents/agents/apply-agent.body.md` | `.cursor/agents/apply-agent.md` |
| CODE_REVIEW | `code-review-agent` | `../../.agents/agents/code-review-agent.body.md` | `.cursor/agents/code-review-agent.md` |
| TEST | `test-agent` | `../../.agents/agents/test-agent.body.md` | `.cursor/agents/test-agent.md` |
| VERIFY | `verify-agent` | `../../.agents/agents/verify-agent.body.md` | `.cursor/agents/verify-agent.md` |
| ARCHIVE | `archive-agent` | `../../.agents/agents/archive-agent.body.md` | `.cursor/agents/archive-agent.md` |

### Cursor 模型分配策略

| Agent | 模型 | 策略说明 |
|-------|------|---------|
| Create Agent | `inherit` | 分析/文档生成使用基础模型 |
| Gate Review Agent | `inherit` | 审查分析使用基础模型 |
| Apply Agent | `deepseek-v4-pro` | 代码生成使用高性能模型 |
| Code Review Agent | `deepseek-v4-pro` | 审查使用不同于 Apply 的强模型 |
| Test Agent | `deepseek-v4-flash` | 测试使用轻量快速模型 |
| Verify Agent | `deepseek-v4-pro` | 最终验证使用高性能模型 |
| Sync Agent | `inherit` | 同步操作用基础模型 |
| Archive Agent | `inherit` | 归档检查用基础模型 |

模型配置在 `.cursor/agents/<agent-ref>.md` 的 frontmatter 中定义，Cursor 自动根据 `subagent_type` 读取并应用。

### 脚本路径

Cursor 适配层的脚本位于项目根 `scripts/` 目录（共享脚本）：

| 脚本 | 路径 |
|------|------|
| 编译检查 | `.agents/scripts/compile_check.ps1` |
| 闸门审查辅助 | `.agents/scripts/gate_review.ps1` |
| 测试运行 | `.agents/scripts/test_runner.ps1` |
| 完整验证 | `.agents/scripts/verify_all.ps1` |

## 调度步骤（CREATE 起）

1. 查 `.agents/workflow/state-machine.yaml` 中 `agent_body_map` 获取当前阶段的 body 文件路径
2. 读取 body 文件内容
3. 查找上方映射表获取对应的 `agent_ref`
4. 组装 prompt（body + 上下文）
5. 使用 Cursor Task 工具调度

```yaml
# 示例：APPLY 阶段
subagent_type: "apply-agent"
description: "代码实现: <change-name>"
prompt: |
  ## Agent 指令

  <../../.agents/agents/apply-agent.body.md 完整内容>

  ---

  ## 当前任务上下文

  - Change Name: <change-name>
  - 项目看板: openspec/changes/<change-name>/session/project-board.yaml
  - 闸门审查结论: openspec/changes/<change-name>/session/GATE-03_gate_review.md

  ## 执行要求
  执行上述 Agent 指令中的所有步骤，产出对应文档。
```

## 与其他平台的差异

| 差异点 | Cursor | Claude Code |
|--------|--------|-------------|
| 调度工具 | `Task` | `Agent` |
| Agent 引用 | `subagent_type: "agent-ref"` (自动读取 .cursor/agents/) | `subagent_type: "general-purpose"` (prompt 注入) |
| 模型选择 | frontmatter `model` 字段 | Agent 工具 `model` 参数 |
| 只读控制 | frontmatter `readonly` 字段 | prompt 指令约束 |
