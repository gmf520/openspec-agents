---
name: /opsx:workflow
id: opsx-workflow
category: Workflow
description: "启动多智能体完整开发工作流 - 从需求分析到归档交付"
parameters:
  - name: change-name
    type: string
    required: true
    description: 变更名称，用作 openspec/changes/ 下的目录名
  - name: requirement
    type: string
    required: false
    description: 需求描述或需求文档路径（可选）
---

启动多智能体开发工作流。

**输入**: `/opsx:workflow <change-name> [需求描述或需求文档路径]`

**示例**:

- `/opsx:workflow add-dark-mode`
- `/opsx:workflow add-auth-system @需求文档.md`
- `/opsx:workflow fix-login-bug`

## 工作流启动流程

收到命令后，MainOrchestrator（你）执行以下步骤：

### 1. 初始化

```
- 解析 change-name 和需求描述
- 运行 openspec list --json 检查是否已存在同名变更
- 如已存在同名变更:
    → 询问用户是恢复还是新建
- 如不存在:
    → 创建变更上下文
```

### 2. 更新项目看板

```yaml
# 在 openspec/changes/<change-name>/session/project-board.yaml 中创建新条目
# 模板参考 .agents/workflow/project-board-template.yaml
active_changes:
  - name: <change-name>
    status: EXPLORE
    retry_counts: { ... }
    created_at: "<timestamp>"
    updated_at: "<timestamp>"
```

### 3. 启动状态机

```
进入 EXPLORE 状态，与用户实时交互开始需求分析。

向用户输出:
  ## 工作流启动: <change-name>

  状态: EXPLORE
  执行者: MainOrchestrator（亲自执行）
  任务: 需求分析与方案探索

  开始执行...
```

### 4. 后续流程

调度子 Agent 的逻辑由 `.claude/rules/multi-agent-workflow.md`（Claude Code 适配规则）和 `.agents/skills/orchestrator-main/SKILL.md`（共享编排核心）共同控制。

---

## ⚠️ MainOrchestrator 职责边界（最高优先级）

MainOrchestrator 是工作流的**唯一调度者**，不是**执行者**（EXPLORE 和 ARCHIVE 用户确认步骤除外）。

### 允许的操作

| 操作 | 说明 |
|------|------|
| 读取文件 | 了解上下文和当前状态 |
| 更新 project-board.yaml | 更新状态、重试计数 |
| 决定路由 | 根据状态机转换条件判断下一阶段 |
| 调度子 Agent | 通过 `Agent` 工具启动子 Agent（传入 change-name 和上下文） |
| 接收报告 | 接收子 Agent 的完成报告 |
| 错误处理 | 根据 error_handling 策略执行回退 |
| 汇报状态 | 向用户汇报工作流状态和阶段完成情况 |

### ❌ 绝对禁止的操作

| 禁止行为 | 说明 |
|---------|------|
| 编写/修改代码 | 任何 `.ts`, `.vue`, `.js`, `.css`, `.html` 等源代码文件 |
| 修改规划制品 | `proposal.md`, `design.md`, `tasks.md`, `specs/` |
| 修改会话制品 | `REQ-01`, `DES-02`, `GATE-03`, `DEV-04`, `CR-05`, `TEST-06`, `VERIFY-07` |
| 执行构建/测试 | 编译、运行测试、执行验证 |
| "代劳"子 Agent | 任何子 Agent 应完成的工作，MainOrchestrator 不得代为执行 |

### 唯一例外

**EXPLORE 阶段**：需与用户实时交互来澄清需求，由 MainOrchestrator 亲自执行。产出仅限 REQ-01 和 DES-02。完成后立即回归纯调度角色。

**ARCHIVE 阶段**：Archive Agent 生成总结 → MainOrchestrator 展示给用户确认 → 确认后 MainOrchestrator 执行归档。

---

## 工作流全貌

```
EXPLORE → CREATE → GATE_REVIEW → APPLY → CODE_REVIEW → TEST → VERIFY → SYNC → ARCHIVE → COMPLETE
```

| 阶段 | Agent | 调度方式 | 模型 | 产出 |
|------|-------|---------|------|------|
| EXPLORE | MainOrchestrator | 直接执行 | - | 需求分析 + 方案设计 |
| CREATE | Create Agent | Agent 子 Agent | sonnet | proposal, design, tasks, specs |
| GATE_REVIEW | Gate Review Agent | Agent 子 Agent | sonnet | 8维度闸门审查 |
| APPLY | Apply Agent | Agent 子 Agent | opus | 代码实现 |
| CODE_REVIEW | Code Review Agent | Agent 子 Agent | opus | 代码评审 |
| TEST | Test Agent | Agent 子 Agent | haiku | 测试报告 |
| VERIFY | Verify Agent | Agent 子 Agent | opus | 验证报告 |
| SYNC | Sync Agent | Agent 子 Agent | sonnet | 规格同步 |
| ARCHIVE | Archive Agent + MO | 混合调度 | sonnet | 归档 + 交付总结 |

## 相关命令

- `/opsx:workflow-status` - 查看工作流状态
- `/opsx:workflow-resume` - 恢复中断的工作流
