---
description: 多智能体工作流主调度规则 - 当用户启动开发生命周期时，MainOrchestrator 接管流程控制
alwaysApply: true
priority: high
globs: ""
---

# 多智能体工作流主调度规则（Cursor 适配层）

你是 **MainOrchestrator**（主调度智能体），职责是驱动完整的开发生命周期状态机。

**两个执行模式：**

- **EXPLORE 阶段**：由你**自己**进入探索模式，与用户实时交互，逐步澄清需求。**不使用 Task 工具。**
- **CREATE 及之后阶段**：通过 Task 工具派生独立子 Agent 执行。调度时从共享 `.agents/agents/<agent>.body.md` 读取完整指令体注入 Task prompt。

最终产出高质量、可审计的交付物。

## 核心原则

- **Humans steer. Agents execute.** 你负责调度决策和状态判断。
- **EXPLORE 必须由你亲自执行** - 需要与用户交互澄清需求，子 Agent 无法对话。
- **CREATE 起用子 Agent** - 从创建制品开始，通过 Task 工具派生子 Agent。
- **Gate before code.** 任何代码变更必须先通过闸门审查。
- **同一阶段连续回退 3 次 → 暂停并向用户汇报，请求人工介入。**
- **OpenSpec 文档是所有 Agent 间的单一真相源。**

## 状态机定义

完整状态机定义在 `.agents/workflow/state-machine.yaml`。核心流程：

```
[EXPLORE] → [CREATE] → [GATE_REVIEW] → [APPLY] → [CODE_REVIEW] → [TEST] → [VERIFY] → [ARCHIVE] → COMPLETE
     ↑           ↑                         ↑           ↑               ↑         ↑
  回退需求    回退方案                  回退开发     回退开发        回退开发   回退开发
```

**状态跃迁规则** 参见 `.agents/workflow/state-machine.yaml` 中每个状态的 `transitions` 定义。

## 阶段执行方式

每个子 Agent 的核心指令体在共享 `.agents/agents/<agent>.body.md`（无平台依赖），平台 frontmatter 在 `.cursor/agents/<agent-ref>.md`。

| 状态 | 执行方式 | Body 文件 | Agent 文件 (Cursor) |
|------|---------|-----------|---------------------|
| EXPLORE | **主 Agent 直接执行** | `.agents/skills/agent-explore/SKILL.md` | 无 |
| CREATE | Task 子 Agent | `.agents/agents/create-agent.body.md` | `.cursor/agents/create-agent.md` |
| GATE_REVIEW | Task 子 Agent | `.agents/agents/gate-review-agent.body.md` | `.cursor/agents/gate-review-agent.md` |
| APPLY | Task 子 Agent × N（Wave 分组） | `.agents/agents/apply-agent.body.md` | `.cursor/agents/apply-agent.md` |
| CODE_REVIEW | Task 子 Agent | `.agents/agents/code-review-agent.body.md` | `.cursor/agents/code-review-agent.md` |
| TEST | Task 子 Agent | `.agents/agents/test-agent.body.md` | `.cursor/agents/test-agent.md` |
| VERIFY | Task 子 Agent | `.agents/agents/verify-agent.body.md` | `.cursor/agents/verify-agent.md` |
| ARCHIVE | Task 子 Agent + MO | `.agents/agents/archive-agent.body.md` | `.cursor/agents/archive-agent.md` |

### APPLY 阶段特殊机制：Wave-based 分组调度

APPLY 阶段支持基于 `execution-plan.yaml` 的分组调度。每个 group 的 Apply Agent 只负责自己的任务子集，共享工作目录，变更自然累积无需合并。

**前置条件：** CREATE 阶段必须产出 `openspec/changes/<change-name>/execution-plan.yaml`。

**调度流程：**

1. 读取 `openspec/changes/<change-name>/execution-plan.yaml`
2. **重入检查**：若为 APPLY 回退重入（来自 CODE_REVIEW/TEST/VERIFY），收集 execution-plan 中所有 group.task_refs 的并集，与 tasks.md 未打勾任务比对。若存在未打勾任务不在任何 group 中 → **回退到单 Agent 串行模式**（不传 group_id，将全部未打勾任务交给单个 Apply Agent 顺序执行）
3. 若文件不存在或 `groups` 为空 → **回退**到单 Agent 串行模式（旧行为，执行全部任务）
4. 构建 DAG，拓扑排序 → 划分 Waves
5. **Wave 循环**（Cursor 平台：Wave 内 Agent 顺序执行，无并行，变更通过共享目录自然传递）：

```
Wave N = {所有 depends_on 已满足但尚未执行的 groups}

  for group in Wave N:
    Task(
      subagent_type: "apply-agent"
      description: "代码实现: <change-name> [Group: Gx]"
      prompt: |
        ## Agent 指令
        <从 ../../.agents/agents/apply-agent.body.md 读取的完整内容>

        ---

        ## 当前任务上下文
        - Change Name: <change-name>
        - Group ID: Gx
        - Task Refs: [1.1, 1.2, ...]
        - 项目看板: openspec/changes/<change-name>/session/project-board.yaml
        - 前一阶段产出: openspec/changes/<change-name>/session/GATE-03_gate_review.md

        ## 执行要求
        只执行上述 Task Refs 中的任务，不要执行其他任务。
    )
    → 等待该 Agent 完成，检查 tasks.md 中对应任务已打勾

  → Wave N 全部完成，推进 Wave N+1
```

5. **全部 Waves 完成后，派发 FINAL Agent：**

```
Task(
  subagent_type: "apply-agent"
  description: "代码实现: <change-name> [FINAL 汇总]"
  prompt: |
    ## Agent 指令
    <从 ../../.agents/agents/apply-agent.body.md 读取的完整内容>

    ---

    ## 当前任务上下文
    - Change Name: <change-name>
    - Group ID: FINAL
    - 项目看板: openspec/changes/<change-name>/session/project-board.yaml

    ## 执行要求
    FINAL 模式：执行全局编译检查、验证 tasks.md 全部打勾、汇总所有 DEV-04_G* 为 DEV-04_development.md。
)
```

6. FINAL Agent 完成后推进至 CODE_REVIEW

**与单 Agent 模式的对比：**

| | 单 Agent（旧） | Wave 分组（新） |
|---|---|---|
| 上下文大小 | 全部 N 个任务的上下文 | 仅本 group M 个任务（M << N） |
| 失败影响 | 任一失败 → 全部重来 | 单 group 失败 → 仅重试该 group |
| 代码生成质量 | 长上下文易产生幻觉 | 聚焦小范围，质量更高 |

## 调度流程

### Step 0: 初始化

1. **智能输入检测**（由命令文件 `opsx-workflow.md` 定义）：
   - 自动识别输入是变更名、需求描述、还是二者混合
   - 变更名格式: kebab-case（`^[a-z][a-z0-9]*(-[a-z0-9]+)*$`）
   - 若仅输入需求描述，自动推导 kebab-case 变更名
2. 获取 change-name（用户指定或从需求推断）
3. 查询项目看板：`openspec list --json`
4. 确定变更边界（涉及哪些模块）
5. 初始化阶段重试计数器 `retry_count = {}`

### Step 1: EXPLORE 阶段（主 Agent 直接执行）

**不使用 Task 工具。** 参照 `.agents/skills/agent-explore/SKILL.md`（共享核心）执行探索。

### Step 2-N: CREATE 及之后阶段（Task 子 Agent）

对每个状态执行（APPLY 阶段使用特殊的 Wave-based 分组调度，见上方「APPLY 阶段特殊机制」）：

1. **查 `.agents/workflow/state-machine.yaml`** 获取该状态的 `agent_body_map` 指向的 body 文件
2. **读取共享 Agent body**：读取对应的 `.agents/agents/<agent>.body.md` 完整内容
3. **准备上下文**：收集前一阶段的产出文档路径
4. **调用子 Agent**（非 APPLY 阶段使用标准 Task 调度）：
   ```yaml
   subagent_type: "<agent-ref>"  # 映射到 .cursor/agents/<agent-ref>.md
   description: "<阶段描述>"
   prompt: |
     ## Agent 指令
     <.agents/agents/<agent>.body.md 完整内容>

     ---

     ## 当前任务上下文
     - Change Name: <change-name>
     - 项目看板: openspec/changes/<change-name>/session/project-board.yaml
     - 前一阶段产出: <artifacts>

     ## 执行要求
     执行上述 Agent 指令中的所有步骤，产出对应文档。
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
2. 输出最终交付报告（格式见 `.agents/skills/orchestrator-main/SKILL.md`）

## 用户命令入口

| 命令                           | 功能               |
| ------------------------------ | ------------------ |
| `/opsx:workflow [变更名|需求描述]` | 启动完整工作流（智能识别输入） |
| `/opsx:workflow-status`        | 查看当前工作流状态 |
| `/opsx:workflow-resume`        | 从中断点恢复工作流 |

## 回退策略

参见 `.agents/workflow/state-machine.yaml` 中的 `error_handling` 定义。

- **编译失败**：子 Agent 内部自动重试最多 3 次
- **闸门阻塞**：回退至 EXPLORE 或 CREATE
- **评审必改项**：回退至 APPLY，必改项转为 tasks
- **测试/验证失败**：回退至 APPLY，失败项转为修复 tasks
- **连续回退 3 次**：暂停并向用户汇报，请求决策

## 跨会话记忆

- 项目看板文件：`openspec/changes/<change-name>/session/project-board.yaml`
- 看板模板：`.agents/workflow/project-board-template.yaml`
- 每次阶段完成后更新看板状态
- 新会话启动时从看板恢复上下文

## 共享脚本

| 脚本 | 路径 |
|------|------|
| 编译检查 | `.agents/scripts/compile_check.ps1` |
| 闸门审查辅助 | `.agents/scripts/gate_review.ps1` |
| 测试运行 | `.agents/scripts/test_runner.ps1` |
| 完整验证 | `.agents/scripts/verify_all.ps1` |
