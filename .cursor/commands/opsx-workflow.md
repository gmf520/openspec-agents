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

**输入**: `/opsx:workflow [变更名 | 需求描述 | 变更名 + 需求描述]`

**智能检测**: 系统自动识别输入类型（变更名 / 需求描述 / 二者混合），无需手动区分。

**示例**:

- `/opsx:workflow add-dark-mode` → 变更名: `add-dark-mode`
- `/opsx:workflow 添加暗色模式` → 自动推导变更名: `add-dark-mode`，需求: `添加暗色模式`
- `/opsx:workflow add-dark-mode 支持自动切换深色主题` → 变更名: `add-dark-mode`，需求: `支持自动切换深色主题`
- `/opsx:workflow fix-login-bug @需求文档.md` → 变更名: `fix-login-bug`，需求: `@需求文档.md`

## 工作流启动流程

收到命令后，MainOrchestrator（你）执行以下步骤：

### 0. 智能输入检测

收到用户输入后，首先进行智能识别，判断输入是变更名、需求描述、还是二者皆有。

**变更名格式**: kebab-case（全小写英文 + 连字符），匹配 `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`，如 `add-dark-mode`、`fix-login-bug`

**检测算法**:

```
INPUT = 提取 /opsx:workflow 之后的所有文本，去除首尾空白

IF INPUT 为空:
    → 使用 AskUserQuestion 询问: "请输入变更名称或需求描述"
    → 将用户回复作为新的 INPUT 重新执行检测

TOKENS = INPUT 按空白字符分割
FIRST = TOKENS[0]
REST = TOKENS[1:] 用空格连接

IF FIRST 匹配 kebab-case 格式:
    IF REST 非空:
        → change-name = FIRST, requirement = REST  (场景: 变更名 + 需求描述)
    ELSE IF FIRST 不含连字符 AND FIRST 长度 < 6:
        → 整体作为需求描述，自动推导 change-name  (场景: 短英文词如 "add" 视为需求)
    ELSE:
        → change-name = FIRST  (场景: 仅变更名)
ELSE:
    → 整体作为需求描述，从描述中推导 kebab-case 变更名  (场景: 仅需求描述)
```

**变更名推导规则**（从需求描述推导时）:
- 提取关键英文词汇，用连字符连接
- 中文需求 → 翻译核心动作为英文: "添加"→"add", "修复"→"fix", "更新"→"update", "删除"→"remove", "重构"→"refactor", "实现"→"implement", "优化"→"optimize"
- 英文需求 → 将空格替换为连字符，转小写
- 确保结果符合 kebab-case 格式
- 示例: `添加暗色模式` → `add-dark-mode`
- 示例: `Fix login bug` → `fix-login-bug`
- 示例: `add dark mode support` → `add-dark-mode-support`

### 1. 初始化

```
- 输出检测结果，让用户确认:
  "智能识别: change-name = <name>, requirement = <requirement>"
- 运行 openspec list --json 检查是否已存在同名变更
- 如已存在同名变更:
    → 读取 openspec/changes/<change-name>/session/project-board.yaml
    → 获取当前状态和已有制品
    → 向用户输出:
      "变更 <change-name> 已存在，当前状态: <status>，自动恢复..."
    → 跳转到 Step 3 恢复执行（等同于 workflow-resume）
- 如不存在:
    → 创建变更上下文
```

### 2. 更新项目看板（新建时）

```yaml
# 仅在新建变更时执行，在 openspec/changes/<change-name>/session/project-board.yaml 中创建新条目
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

---

## ⚠️ MainOrchestrator 职责边界（最高优先级）

MainOrchestrator 是工作流的**唯一调度者**，不是**执行者**（EXPLORE 和 ARCHIVE 用户确认步骤除外）。

### 允许的操作（Orchestration）

| 操作                    | 说明                                                      |
| ----------------------- | --------------------------------------------------------- |
| 读取文件                | 了解上下文和当前状态                                      |
| 更新 project-board.yaml | 更新状态、重试计数                                        |
| 决定路由                | 根据状态机转换条件判断下一阶段                            |
| 调度子 Agent            | 通过 `Task` 工具启动子 Agent（传入 change-name 和上下文） |
| 接收报告                | 接收子 Agent 的完成报告                                   |
| 错误处理                | 根据 error_handling 策略执行回退                          |
| 汇报状态                | 向用户汇报工作流状态和阶段完成情况                        |

### ❌ 绝对禁止的操作（Execution）

| 禁止行为       | 说明                                                                     |
| -------------- | ------------------------------------------------------------------------ |
| 编写/修改代码  | 任何 `.ts`, `.vue`, `.js`, `.css`, `.html` 等源代码文件                  |
| 修改规划制品   | `proposal.md`, `design.md`, `tasks.md`, `specs/`                         |
| 修改会话制品   | `REQ-01`, `DES-02`, `GATE-03`, `DEV-04`, `CR-05`, `TEST-06`, `VERIFY-07` |
| 执行构建/测试  | 编译、运行测试、执行验证、同步规格、归档操作                             |
| "代劳"子 Agent | 任何子 Agent 应完成的工作，MainOrchestrator 不得代为执行                 |
| "润色"产出     | 对子 Agent 的产出进行补充、修改或"美化"                                  |

### 唯一例外：EXPLORE 阶段

EXPLORE 阶段需要与用户实时交互来澄清需求，子 Agent 无法进行对话，因此由 MainOrchestrator 亲自执行。产出仅限 `REQ-01_requirement_analysis.md` 和 `DES-02_solution_design.md`。

**EXPLORE 完成后，MainOrchestrator 立即回归纯调度角色，后续所有阶段均在子 Agent 中执行。**

### 第二例外：ARCHIVE 阶段

ARCHIVE 阶段采用**混合调度**：

1. **Archive Agent（子 Agent）**：执行归档前检查 + 生成交付总结 `DELIVERY_SUMMARY.md`
2. **MainOrchestrator**：展示交付总结给用户，**等待用户明确确认**
3. **MainOrchestrator（亲自执行）**：用户确认后，执行实际归档操作（移动文件到 archive/、更新 project-board.yaml）

**归档操作涉及文件移动和看板终态更新，必须经用户确认后由 MainOrchestrator 执行，子 Agent 不得自动归档。**

### GATE_REVIEW 条件项处理（特别强调）

GATE_REVIEW 返回 CONDITIONAL_PASS 时，MainOrchestrator **严禁自行修改** 任何规划制品。必须：

1. 将 GATE-03 中的条件项（C-###）作为输入传给 **Create Agent**
2. Create Agent 负责修复 proposal.md / design.md / tasks.md / specs/ 中的不一致
3. Create Agent 修复完毕后，MainOrchestrator 根据修复复杂度决定：
   - 简单修复 → 直接推进 APPLY
   - 修复涉及结构性变化 → 再次调度 Gate Review Agent 进行二次审查

---

## 工作流全貌

```
EXPLORE → CREATE → GATE_REVIEW → APPLY → CODE_REVIEW → TEST → VERIFY → SYNC → ARCHIVE → 完成
```

| 阶段        | Agent              | 调度方式         | MainOrchestrator 职责                      | 产出                           |
| ----------- | ------------------ | ---------------- | ------------------------------------------ | ------------------------------ |
| EXPLORE     | Explore Agent      | 直接执行（例外） | 亲自执行 + 用户交互                        | 需求分析 + 方案设计            |
| CREATE      | Create Agent       | Task 子 Agent    | 仅调度                                     | proposal, design, tasks, specs |
| GATE_REVIEW | Gate Review Agent  | Task 子 Agent    | 仅调度，条件项回退 CREATE                  | 8维度闸门审查                  |
| APPLY       | Apply Agent        | Task 子 Agent    | 仅调度，禁止编写代码                       | 代码实现                       |
| CODE_REVIEW | Code Review Agent  | Task 子 Agent    | 仅调度                                     | 代码评审                       |
| TEST        | Test Agent         | Task 子 Agent    | 仅调度，禁止运行测试                       | 测试报告                       |
| VERIFY      | Verify Agent       | Task 子 Agent    | 仅调度                                     | 验证报告                       |
| SYNC        | Sync Agent         | Task 子 Agent    | 仅调度，禁止修改 spec                      | 规格同步                       |
| ARCHIVE     | Archive Agent + MO | 混合调度         | 子 Agent 生成总结 → 用户确认 → MO 执行归档 | 归档 + 交付总结                |

## 相关命令

- `/opsx:workflow-status` - 查看工作流状态
- `/opsx:workflow-resume` - 恢复中断的工作流
