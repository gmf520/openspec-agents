---

## name: /opsx-workflow-status

id: opsx-workflow-status
category: Workflow
description: "查看多智能体工作流的当前状态和进度"

查看多智能体开发工作流的当前状态。

**输入**: 无（自动从项目看板读取）

## 执行步骤

1. **读取项目看板**
  读取 `workflow/project-board.yaml` 获取所有活跃变更。
2. **检查 OpenSpec 状态**
  ```bash
   openspec list --json
  ```
3. **输出状态报告**
  ### 格式
4. **如果没有活跃变更**
  ```
   ## 工作流状态报告

   当前没有活跃的开发工作流。

   使用 `/opsx:workflow <change-name>` 启动一个新工作流。
  ```

