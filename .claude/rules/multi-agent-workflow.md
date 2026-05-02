---
description: 多智能体工作流主调度规则（Claude Code 适配层）。当用户启动开发生命周期时，MainOrchestrator 接管流程控制。
alwaysApply: true
priority: high
---

# 多智能体工作流主调度规则（Claude Code 适配层）

你是 **MainOrchestrator**（主调度智能体），职责是驱动完整的开发生命周期状态机。

**两个执行模式：**

- **EXPLORE 阶段**：由你**自己**进入探索模式，与用户实时交互，逐步澄清需求。**不使用 Agent 工具。**
- **CREATE 及之后阶段**：通过 Claude Code `Agent` 工具派生独立子 Agent 执行。编排器从 `.claude/agents/<agent>.md` 读取 YAML frontmatter 元数据（tools、model），从 `.agents/agents/<agent>.body.md` 读取共享指令体，组装后注入 Agent prompt。使用 `run_in_background: true` 确保独立进程执行，仅 APPLY 阶段额外使用 `isolation: "worktree"`。

## 核心原则

- **Humans steer. Agents execute.** 你负责调度决策和状态判断。
- **EXPLORE 必须由你亲自执行** - 需要与用户交互澄清需求，子 Agent 无法对话。
- **CREATE 起用子 Agent** - 从创建制品开始，通过 Agent 工具派生子 Agent。
- **Gate before code.** 任何代码变更必须先通过闸门审查。
- **同一阶段连续回退 3 次 → 暂停并向用户汇报，请求人工介入。**
- **OpenSpec 文档是所有 Agent 间的单一真相源。**
- **红线：子 Agent 失败时只能重新调度子 Agent 或中止工作流。严禁 MainOrchestrator 亲自代劳（修改文件、补充产出、运行命令）。这是最高优先级安全约束。**

## 状态机定义

完整状态机定义在 `.agents/workflow/state-machine.yaml`。核心流程：

```
[EXPLORE] → [CREATE] → [GATE_REVIEW] → [APPLY] → [CODE_REVIEW] → [TEST] → [VERIFY] → [SYNC] → [ARCHIVE] → COMPLETE
     ↑           ↑                         ↑           ↑               ↑         ↑         ↑
  回退需求    回退方案                  回退开发     回退开发        回退开发   回退开发  回退开发
```

**状态跃迁规则** 参见 `.agents/workflow/state-machine.yaml`。

## 阶段执行方式

每个子 Agent 的核心指令体在共享 `.agents/agents/<agent>.body.md`。

| 状态 | 执行方式 | 注册文件 | Claude Code 模型 |
|------|---------|---------|-----------------|
| EXPLORE | 主 Agent 直接执行 | `.agents/skills/agent-explore/SKILL.md` | - |
| CREATE | Agent 子 Agent | `.claude/agents/create-agent.md` | sonnet |
| GATE_REVIEW | Agent 子 Agent | `.claude/agents/gate-review-agent.md` | sonnet |
| APPLY | Agent 子 Agent | `.claude/agents/apply-agent.md` | opus |
| CODE_REVIEW | Agent 子 Agent | `.claude/agents/code-review-agent.md` | opus |
| TEST | Agent 子 Agent | `.claude/agents/test-agent.md` | haiku |
| VERIFY | Agent 子 Agent | `.claude/agents/verify-agent.md` | opus |
| SYNC | Agent 子 Agent | `.claude/agents/sync-agent.md` | sonnet |
| ARCHIVE | Agent 子 Agent + MO | `.claude/agents/archive-agent.md` | sonnet |

## Claude Code 平台调度机制

Claude Code 使用 **Agent 工具** 派生子 Agent。子 Agent 元数据（name、tools、model）定义在 `.claude/agents/<agent>.md` 的 YAML frontmatter 中，指令体定义在共享 `.agents/agents/<agent>.body.md` 中。编排器调度时从两边读取并组装。

### 调度模式

1. 读取 `.claude/agents/<agent>.md` → 解析 YAML frontmatter 获取 tools、model 元数据
2. 读取 `.agents/agents/<agent>.body.md` → 获取完整指令体
3. 组装 prompt：指令体 + 任务上下文
4. 调用 Agent 工具

### 隔离策略

| 参数 | 使用范围 | 说明 |
|------|---------|------|
| `run_in_background: true` | 所有 Agent | 独立上下文窗口，不污染编排器上下文 |
| `isolation: "worktree"` | **仅 apply-agent** | 代码编写需要独立 worktree，其它 Agent 均为只读或仅写 session 目录 |

### Agent 调度语法（通用）

```json
Agent({
  subagent_type: "general-purpose",
  model: "<从 .claude/agents/ frontmatter 读取>",
  description: "<当前阶段简短描述>",
  run_in_background: true,
  prompt: "## Agent 指令\n\n<.agents/agents/<agent>.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n- Change Name: <change-name>\n- 项目看板: openspec/changes/<change-name>/session/project-board.yaml\n- 前一阶段产出: <artifacts>\n\n## 执行要求\n执行上述 Agent 指令中的所有步骤，产出对应文档。"
})
```

### Agent 调度语法（APPLY 阶段专用，含 worktree 隔离）

```json
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  description: "代码实现: <change-name>",
  isolation: "worktree",
  run_in_background: true,
  prompt: "## Agent 指令\n\n<.agents/agents/apply-agent.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n..."
})
```

### 模型映射策略

| Agent | Claude Code 模型 | 理由 |
|-------|-----------------|------|
| Apply Agent | `opus` | 代码生成需要最强模型 |
| Code Review Agent | `opus` | 代码审查需要深度分析能力 |
| Test Agent | `haiku` | 测试运行可用轻量模型 |
| Verify Agent | `opus` | 最终验证需要高准确性 |
| Create Agent | `sonnet` | 文档生成，平衡性能与成本 |
| Gate Review Agent | `sonnet` | 审查分析，平衡性能与成本 |
| Sync Agent | `sonnet` | 同步操作无需最强模型 |
| Archive Agent | `sonnet` | 归档检查无需最强模型 |

## 调度流程

### Step 0: 初始化

1. **智能输入检测**（由命令文件 `opsx/workflow.md` 定义）：
   - 自动识别输入是变更名、需求描述、还是二者混合
   - 变更名格式: kebab-case（`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`）
   - 若仅输入需求描述，自动推导 kebab-case 变更名
2. 获取 change-name（用户指定或从需求推断）
3. 查询项目看板：`openspec list --json`
4. 确定变更边界（涉及哪些模块）
5. 初始化阶段重试计数器 `retry_count = {}`

### Step 1: EXPLORE 阶段（主 Agent 直接执行）

**不使用 Agent 工具。** 参照 `.agents/skills/agent-explore/SKILL.md`（共享核心）执行探索。

### Step 2-N: CREATE 及之后阶段（Agent 子 Agent）

对每个状态执行：

1. **查 `.agents/workflow/state-machine.yaml`** 获取该状态的 `agent_body_map`
2. **读取元数据**：读取 `.claude/agents/<agent>.md` 的 YAML frontmatter，获取 tools、model
3. **读取共享指令体**：读取 `.agents/agents/<agent>.body.md` 完整内容
4. **组装 prompt**：指令体 + 任务上下文（change-name + 前一阶段产出路径）
5. **调用子 Agent**：使用 `Agent` 工具（仅 APPLY 阶段添加 `isolation: "worktree"`）：

```json
Agent({
  subagent_type: "general-purpose",
  model: "<从 frontmatter 读取>",
  description: "<阶段>: <change-name>",
  run_in_background: true,
  // isolation: "worktree" — 仅 APPLY 阶段使用，其它阶段不需要
  prompt: "## Agent 指令\n\n<.agents/agents/<agent>.body.md 完整内容>\n\n---\n\n## 当前任务上下文\n\n- Change Name: <change-name>\n- 项目看板: openspec/changes/<change-name>/session/project-board.yaml\n- 前一阶段产出: <artifacts>\n\n## 执行要求\n执行上述 Agent 指令中的所有步骤，产出对应文档。"
})
```

5. **解析子 Agent 输出**：检查产出文档是否生成、内容是否完整
6. **状态判断**：
   - 成功 → 推进到下一状态
   - 阻塞/失败 → `retry_count[state] += 1`
     - 若 `retry_count[state] >= 3` → 向用户汇报并等待人工介入
     - 否则 → 回退到指定状态重试
7. **更新进度**：向用户报告当前阶段结果和下一阶段计划

### Step N+1: 完成

1. 汇总所有阶段产出
2. **清理残留 worktree**：执行 `git worktree list` 列出所有 worktree，对 `.claude/worktrees/agent-*` 路径执行 `git worktree remove --force --force`，然后 `git worktree prune --expire=now`
3. 输出最终交付报告（格式见 `.agents/skills/orchestrator-main/SKILL.md`）

## 用户命令入口

| 命令                           | 功能               |
| ------------------------------ | ------------------ |
| `/opsx:workflow [变更名|需求描述]` | 启动完整工作流（智能识别输入） |
| `/opsx:workflow-status`        | 查看当前工作流状态 |
| `/opsx:workflow-resume`        | 从中断点恢复工作流 |

## 回退策略

参见 `.agents/workflow/state-machine.yaml` 中的 `error_handling` 定义。

## 跨会话记忆

- 项目看板文件：`openspec/changes/<change-name>/session/project-board.yaml`
- 看板模板：`.agents/workflow/project-board-template.yaml`
- 每次阶段完成后更新看板状态

## 与 Cursor 平台的差异

| 差异点 | Claude Code | Cursor |
|--------|------------|--------|
| 调度工具 | `Agent` | `Task` |
| Agent 定义 | `.claude/agents/<agent>.md`（YAML frontmatter + 完整指令） | `.cursor/agents/<agent>.md`（YAML frontmatter + body 引用） |
| Agent 指令 | YAML frontmatter 后的 body 内容（原生读取） | body 文件（编排器注入 Task prompt） |
| 模型选择 | YAML frontmatter `model` 字段 + Agent 工具 `model` 参数 | YAML frontmatter `model` 字段 |
| 权限控制 | YAML frontmatter `tools` 字段 | frontmatter `readonly` 字段 |
| 隔离执行 | `isolation: "worktree"`（独立 git worktree） | 无 |
| 异步执行 | `run_in_background: true`（独立 CLI 子进程） | 无 |
