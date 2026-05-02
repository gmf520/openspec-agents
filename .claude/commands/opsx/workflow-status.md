---
name: /opsx:workflow-status
id: opsx-workflow-status
category: Workflow
description: "查看多智能体工作流当前状态"
---

查看当前工作流状态。

**输入**: `/opsx:workflow-status`

**输出**: 当前活跃变更的状态总览。

## 执行步骤

MainOrchestrator（你）执行以下操作：

### 1. 扫描活跃变更

```bash
openspec list --json
```

### 2. 读取看板状态

对每个活跃变更，读取其 `openspec/changes/<change-name>/session/project-board.yaml`。

### 3. 输出状态报告

```
## 工作流状态总览

### 活跃变更

| 变更名称 | 当前阶段 | 重试次数 | 最后更新 |
|---------|---------|---------|---------|
| <name>  | <stage> | N       | <time>  |

### 已完成变更

| 变更名称 | 完成时间 | 归档路径 |
|---------|---------|---------|
| <name>  | <time>  | archive/<name>/ |

---

### 详情: <active-change-name>

**当前阶段:** <stage>
**重试计数:**
- EXPLORE: N | CREATE: N | GATE_REVIEW: N | APPLY: N | CODE_REVIEW: N | TEST: N | VERIFY: N | SYNC: N

**已有制品:**
- <list artifacts>

**下一步:** <next-stage>（由 <Agent> 执行）

---

如需恢复中断的工作流，使用 `/opsx:workflow-resume`。
```
