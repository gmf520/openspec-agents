---

## name: /opsx-workflow

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
# 在 workflow/project-board.yaml 中创建新条目
active_changes:
  - name: <change-name>
    status: EXPLORE
    retry_counts: { ... }
    created_at: "<timestamp>"
    updated_at: "<timestamp>"
```

### 3. 启动状态机

```
进入 EXPLORE 状态，调度 Explore Agent 开始需求分析。

向用户输出:
  ## 工作流启动: <change-name>

  状态: EXPLORE
  执行者: Explore Agent
  任务: 需求分析与方案探索

  开始执行...
```

### 4. 后续流程

调度子 Agent 的逻辑由 `orchestrator-main` skill 和 `multi-agent-workflow` rule 控制。

## 工作流全貌

```
EXPLORE → CREATE → GATE_REVIEW → APPLY → CODE_REVIEW → TEST → VERIFY → SYNC → ARCHIVE → 完成
```

| 阶段        | Agent             | 产出                           |
| ----------- | ----------------- | ------------------------------ |
| EXPLORE     | Explore Agent     | 需求分析 + 方案设计            |
| CREATE      | Create Agent      | proposal, design, tasks, specs |
| GATE_REVIEW | Gate Review Agent | 8维度闸门审查                  |
| APPLY       | Apply Agent       | 代码实现                       |
| CODE_REVIEW | Code Review Agent | 代码评审                       |
| TEST        | Test Agent        | 测试报告                       |
| VERIFY      | Verify Agent      | 验证报告                       |
| SYNC        | Sync Agent        | 规格同步                       |
| ARCHIVE     | Archive Agent     | 归档                           |

## 相关命令

- `/opsx:workflow-status` - 查看工作流状态
- `/opsx:workflow-resume` - 恢复中断的工作流
