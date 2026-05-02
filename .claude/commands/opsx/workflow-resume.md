---
name: /opsx:workflow-resume
id: opsx-workflow-resume
category: Workflow
description: "从中断点恢复多智能体工作流"
---

从中断点恢复工作流。

**输入**: `/opsx:workflow-resume [change-name]`

- 指定 `change-name`：恢复特定变更
- 不指定：列出所有可恢复的变更供选择

## 执行步骤

MainOrchestrator（你）执行以下操作：

### 1. 发现可恢复的变更

```bash
openspec list --json
```

筛选出状态不是 COMPLETE 的变更。

### 2. 读取看板状态

```bash
# 读取该变更的项目看板
cat openspec/changes/<change-name>/session/project-board.yaml
```

### 3. 恢复上下文

从 `project-board.yaml` 中恢复：
- 当前状态 (`status`)
- 重试计数 (`retry_counts`)
- 已有制品路径 (`artifacts`)
- 上次更新时间

### 4. 从中断点继续

```
向用户输出:
  ## 工作流恢复: <change-name>

  当前状态: <current-stage>
  上次更新: <timestamp>
  已有制品: <list>

  从 <current-stage> 继续执行...

```

然后从 `current-stage` 开始，按照状态机跃迁规则继续推进。

### 5. 中断阶段处理

如果中断发生在子 Agent 执行过程中（制品未生成或有输出不完整）：
- 检查 `project-board.yaml` 中该阶段的 `artifacts` 是否有产出路径
- 有产出 → 检查文件是否完整，完整则视为已完成
- 无产出或文件不完整 → 重新调度该阶段

---

## 恢复示例

```
用户: /opsx:workflow-resume fix-login-bug

MainOrchestrator:
  ## 工作流恢复: fix-login-bug

  当前状态: CODE_REVIEW (上一次完成: APPLY)
  APPLY 重试: 1/3
  已有制品: REQ-01, DES-02, GATE-03, proposal, design, tasks, DEV-04

  从 CODE_REVIEW 继续执行...

  调度 Code Review Agent...
```
