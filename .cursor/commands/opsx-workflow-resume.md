---

## name: /opsx-workflow-resume
id: opsx-workflow-resume
category: Workflow
description: "恢复之前中断的多智能体工作流"

恢复一个中断的多智能体开发工作流。

**输入**: 可选 `<change-name>`。如未指定，列出所有可恢复的变更供选择。

## 执行步骤

### 1. 确定要恢复的变更

```
- 如果用户指定了 <change-name>，直接使用
- 否则:
  1. 读取 workflow/project-board.yaml
  2. 列出所有非 COMPLETE 状态的活跃变更
  3. 让用户选择要恢复哪个
```

### 2. 恢复上下文

```
1. 从 workflow/project-board.yaml 读取:
   - 当前状态
   - 重试计数
   - 已完成阶段的 artifacts 路径

2. 读取已完成阶段的产出文档，恢复上下文

3. 运行 openspec status --change "<name>" --json
   确认 OpenSpec 中的状态与项目看板一致
```

### 3. 从断点继续

```
从项目看板记录的状态继续执行。

向用户输出:
  ## 工作流恢复: <change-name>

  从中断点恢复...
  状态: <current-state>
  已完成: <已完成阶段列表>
  下一阶段: <current-state>

  由 <Agent> 继续执行...
```

### 4. 异常处理

```
- 如果看板中记录的状态与 OpenSpec 实际状态不一致:
    → 以 OpenSpec 实际状态为准，更新看板
    → 告知用户状态被修复

- 如果变更的 artifacts 丢失或损坏:
    → 回退到最近一个完整的阶段
    → 告知用户需要重新执行哪些阶段
```

