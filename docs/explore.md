# 多智能体AI开发工作流设计

## 一、文章核心设计分析

### 1.1 智能体定义体系（7个角色）

文章([https://mp.weixin.qq.com/s/NtsksL2gkMtMqkILi4xvRg](https://mp.weixin.qq.com/s/NtsksL2gkMtMqkILi4xvRg)) 构建了七个专职Agent的协作体系：


| Agent               | 模型                            | 职责               |
| ------------------- | ----------------------------- | ---------------- |
| PM Orchestrator     | composer-2                    | 流程总控，协调阶段推进与决策   |
| Requirement Analyst | composer-2                    | 需求分析，拆解多义性，定验收标准 |
| Solution Architect  | composer-2                    | 方案设计，模块划分，接口定义   |
| Gate Reviewer       | composer-2                    | 8维度闸门审查，拦截设计缺陷   |
| Developer Agent     | claude-4.6-opus-high-thinking | 代码实现，按方案落地       |
| Code Reviewer       | gpt-5.4-medium                | 代码评审，发现自审盲区      |
| QA Tester           | composer-2                    | 测试验证，维护自动化测试     |


模型选择策略：只有Developer Agent使用最贵模型处理代码生成，其余6个均使用轻量模型处理文档工作。

### 1.2 状态机设计

PM Orchestrator运行一套严格的状态机：

```
[需求分析] → [方案设计] → [闸门评估] → [开发实现] → [代码评审] → [测试验证] → [交付]
    ↑              ↑                        ↑              ↑
 回退需求/方案  回退需求/方案              回退开发        回退开发
```

核心规则：

- **闸门有阻塞项 → 不许开工，必须回退**
- **评审有必改项 → 不许进测试，必须回退**
- **测试有阻塞缺陷 → 回退到开发修**
- **同一阶段连续回退3次 → 停止并汇报用户**

每个Agent的输出是落地的文档，按固定目录结构存放：

```
docs/features/<feature-name>/
├── 01_REQUIREMENT_ANALYSIS.md
├── 02_SOLUTION_DESIGN.md
├── 03_GATE_REVIEW.md
├── 04_DEVELOPMENT.md
├── 05_CODE_REVIEW.md
└── 06_TEST_REPORT.md
```

### 1.3 三层架构：Rules / Skills / Scripts

文章从实践中提炼出三层分离架构：

- **流程Rule**：`alwaysApply: true`，确保AI不遗漏关键流程（如"改完代码必须跑验证"）
- **Skill**：封装操作步骤（如`post-verify/SKILL.md` + `.bat`），告诉AI怎么操作
- **Script**：执行实际的自动化检测（如`verify_all.ps1`跑14项检查）

三层的关系：Rule保证不遗漏流程，Skill封装执行步骤，Script机械化执行检查。

---

## 二、OpenSpec与OPSX命令体系

### 2.1 核心命令

OpenSpec是一套规范驱动开发框架，OPSX是其核心工作流系统，主要命令：


| 命令              | 功能                                            |
| --------------- | --------------------------------------------- |
| `/opsx:explore` | 探索式对话，调研方案、梳理思路、明确需求                          |
| `/opsx:ff`      | 快速生成所有规划制品（proposal + specs + design + tasks） |
| `/opsx:apply`   | 执行变更任务，编写代码实现功能                               |
| `/opsx:verify`  | 验证代码实现与制品要求是否一致                               |
| `/opsx:sync`    | 将变更的增量规格合并到主规格                                |
| `/opsx:archive` | 归档已完成的变更，留存审计                                 |


### 2.2 核心工作流

OpenSpec的标准流程：

```
explore → create(ff) → apply → archive
```

### 2.3 两种工作模式

- **默认（core）模式**：propose → explore → apply → archive，适合需求明确的简单场景
- **扩展模式**：new → continue → ... → verify → sync，提供分步控制

---

## 三、文章设计与OpenSpec的对应关系

通过分析，可以发现文章中的Harness Engineering实践与OpenSpec的opsx命令存在清晰的映射：


| 文章的Agent/环节               | 对应opsx命令                       | 说明           |
| ------------------------- | ------------------------------ | ------------ |
| **PM Orchestrator（流程总控）** | 整体调度逻辑                         | 主Agent控制流程判断 |
| **Requirement Analyst**   | `/opsx:explore`                | 需求探索与分析      |
| **Solution Architect**    | `/opsx:explore` + 设计阶段         | 方案设计与架构      |
| **PM创建阶段文档**              | `/opsx:ff`                     | 批量生成规划制品     |
| **Gate Reviewer**         | `/opsx:verify`（开发前验证）          | 闸门审查，拦截设计问题  |
| **Developer Agent**       | `/opsx:apply`                  | 代码实现         |
| **Code Reviewer**         | `/opsx:verify`（代码验证）           | 代码审查与验证      |
| **QA Tester**             | `/opsx:verify`（测试验证）           | 测试执行与验证      |
| **事后验证**                  | `/opsx:verify`（运行验证脚本）         | 编译+测试+14项检查  |
| **归档**                    | `/opsx:sync` + `/opsx:archive` | 合并规格，归档完成    |


关键对应逻辑：**OpenSpec的opsx命令天然适合作为多Agent之间的通信协议**，每一阶段的工作成果以OpenSpec文档格式输出，构成Agent间交接的"单一真相源"。

---

## 四、多智能体AI开发工作流设计

### 4.1 整体架构

```
                        ┌─────────────────────────────┐
                        │    Main Orchestrator Agent   │
                        │      (PM Agent)              │
                        │  - 状态机驱动                │
                        │  - OpenSpec文档通信          │
                        │  - 子Agent调度               │
                        └──────────┬──────────────────┘
                                   │
          ┌────────────────────────┼────────────────────────┐
          │                        │                        │
  ┌───────▼───────┐     ┌─────────▼────────┐     ┌────────▼────────┐
  │  Explore Agent│     │  Create Agent    │     │  Apply Agent    │
  │ (需求分析+方案)│     │ (规划制品生成)   │     │ (代码实现)      │
  │ opsx:explore  │     │ opsx:ff          │     │ opsx:apply      │
  └───────┬───────┘     └─────────┬────────┘     └────────┬────────┘
          │                       │                       │
  ┌───────▼───────┐     ┌─────────▼────────┐     ┌────────▼────────┐
  │  Verify Agent │     │  Sync Agent      │     │  Archive Agent  │
  │ (闸门+代码+测试│     │ (规格同步)       │     │ (归档)          │
  │  验证)        │     │ opsx:sync        │     │ opsx:archive    │
  │ opsx:verify   │     │                  │     │                 │
  └───────────────┘     └──────────────────┘     └─────────────────┘
```

### 4.2 主Agent（Main Orchestrator）定义

```
Agent名称: MainOrchestrator
角色: 流程总调度者
模型: composer-2（轻量模型，处理调度逻辑和OpenSpec文档解析）
```

**核心能力：**

1. **状态机管理**：维护工作流状态，判断阶段推进/回退
2. **OpenSpec文档解析**：读取各阶段输出的proposal/specs/design/tasks文档，评估完成度
3. **子Agent调度**：根据当前状态，决定调用哪个子Agent
4. **进度追踪**：维护项目级任务看板，提供跨会话"记忆"

**工作状态定义：**

```
State: EXPLORE
├── → State: CREATE（explore完成并满足创建条件）
└── → 回退至EXPLORE（方案不完善）
State: CREATE
├── → State: GATE_REVIEW（规划制品生成完毕）
└── → 回退至CREATE（制品不完整）
State: GATE_REVIEW
├── → State: APPLY（闸门通过）
├── → 回退至EXPLORE（闸门阻塞，需重新分析）
└── → 回退至CREATE（闸门有条件通过，需调整方案）
State: APPLY
├── → State: CODE_REVIEW（实现完成）
└── → 回退至APPLY（编译失败）
State: CODE_REVIEW
├── → State: TEST（评审通过）
└── → 回退至APPLY（有必改项）
State: TEST
├── → State: VERIFY（测试通过）
└── → 回退至APPLY（有阻塞缺陷）
State: VERIFY
├── → State: SYNC（验证通过）
└── → 回退至APPLY（验证失败）
State: SYNC
├── → State: ARCHIVE（规格同步完成）
└── → 回退至APPLY（同步冲突）
State: ARCHIVE
└── → 完成
```

### 4.3 子Agent定义

**SubAgent 1: Explore Agent**

```
触发条件: MainOrchestrator检测到当前状态为EXPLORE
执行命令: /opsx:explore [topic]
产出文档: REQ-01_requirement_analysis.md（需求分析文档）
          DES-02_solution_design.md（方案设计文档）
```

**SubAgent 2: Create Agent**

```
触发条件: MainOrchestrator确认EXPLORE阶段完成，进入CREATE状态
执行命令: /opsx:ff [change-name]
产出文档: openspec/changes/<change-name>/
          ├── proposal.md
          ├── design.md
          ├── tasks.md
          └── specs/<domain>/spec.md
```

**SubAgent 3: Gate Review Agent**

```
触发条件: MainOrchestrator确认CREATE阶段完成，进入GATE_REVIEW状态
执行工具: 闸门审查skill（读取proposal/design/specs，执行8维度审查）
产出文档: GATE-03_gate_review.md（包含通过/有条件通过/阻塞判定）
```

**SubAgent 4: Apply Agent**

```
触发条件: MainOrchestrator确认GATE_REVIEW通过，进入APPLY状态
执行命令: /opsx:apply
         + compile skill（编译检查）
产出文档: DEV-04_development.md（开发记录，含编译结果）
```

**SubAgent 5: Code Review Agent**

```
触发条件: MainOrchestrator确认APPLY完成，进入CODE_REVIEW状态
执行工具: 代码审查skill（读取tasks完成情况、diff文件、编码规范）
产出文档: CR-05_code_review.md（包含PASS/MUST_FIX/SUGGEST分类）
```

**SubAgent 6: Test Agent**

```
触发条件: MainOrchestrator确认CODE_REVIEW通过，进入TEST状态
执行命令: test skill（运行测试套件）+ /opsx:verify（初步验证）
产出文档: TEST-06_test_report.md
```

**SubAgent 7: Verify Agent**

```
触发条件: MainOrchestrator确认TEST通过，进入VERIFY状态
执行命令: /opsx:verify（完整验证）
         + custom verify skill（如verify_all.ps1等自定义验证脚本）
产出文档: VERIFY-07_verification_report.md
```

**SubAgent 8: Sync Agent**

```
触发条件: MainOrchestrator确认VERIFY通过，进入SYNC状态
执行命令: /opsx:sync
产出文档: 更新的openspec/specs/<domain>/spec.md
```

**SubAgent 9: Archive Agent**

```
触发条件: MainOrchestrator确认SYNC完成，进入ARCHIVE状态
执行命令: /opsx:archive
产出文档: 归档到openspec/changes/archive/<change-name>/
```

### 4.4 通信协议：OpenSpec文档格式

所有Agent之间的交接均以OpenSpec定义的文档格式为标准通信协议：

```markdown
# 以proposal.md为例 - 主Agent与子Agent间的标准协议

## Proposal: <change-name>
### Intent（意图）
<!-- Explore Agent分析后，Create Agent据此生成 -->

### Scope（范围）
<!-- 明确修改边界 -->

### Approach（方法）
<!-- Solution Architect的设计决策 -->

### Tasks（任务清单）
<!-- Create Agent生成的tasks.md，供Apply Agent执行 -->

### Gate Status（闸门状态）
<!-- Gate Review Agent填写的审查结论 -->

### Verification Report（验证报告）
<!-- Verify Agent填写的验证结果 -->
```

### 4.5 工作流闭环与状态机实现

**主Agent调度伪代码：**

```python
class MainOrchestrator:
    def __init__(self):
        self.state = "EXPLORE"
        self.state_machine = StateMachine()
        self.project_board = ProjectBoard()  # 项目级任务看板
        self.retry_count = {state: 0 for state in self.states}
        
    def run(self, change_request: str):
        while self.state != "COMPLETE":
            # 1. 查询项目看板，获取历史上下文
            history_context = self.project_board.search_related(change_request)
            
            # 2. 根据当前状态决定子Agent
            sub_agent = self.select_sub_agent(self.state)
            
            # 3. 准备OpenSpec通信文档
            spec_doc = self.prepare_spec_document(
                state=self.state,
                previous_outputs=self.get_previous_outputs(),
                history=history_context
            )
            
            # 4. 调用子Agent执行opsx命令
            result = sub_agent.execute(
                opsx_command=self.get_opsx_command(self.state),
                spec_document=spec_doc
            )
            
            # 5. 解析子Agent输出（OpenSpec文档）
            parsed_output = self.parse_open_spec_output(result)
            
            # 6. 状态机判断：推进、回退还是停止
            next_state = self.evaluate_next_state(
                current_state=self.state,
                result=parsed_output
            )
            
            # 7. 处理回退逻辑
            if next_state == "ROLLBACK":
                self.handle_rollback()
            elif next_state == "HUMAN_INTERVENTION":
                self.report_to_human()
            else:
                self.state = next_state
                
            # 8. 更新项目看板
            self.project_board.update(self.state, result)
```

**错误处理与重试策略：**

1. **编译失败**：Apply Agent内自动重试（最多3次），每次将编译错误反馈给主Agent
2. **闸门阻塞**：回退至EXPLORE或CREATE，将Gate Review文档作为新的上下文
3. **评审必改项**：回退至APPLY，将Code Review文档中的必改项转为任务
4. **验证失败**：回退至APPLY，将验证报告中的FAIL项转为修复任务
5. **连续回退3次**：暂停流程，向用户汇报当前状态和阻塞原因，请求人工介入

### 4.6 完整流程步骤

**Step 1: 需求启动**

```
用户: @需求文档.md + "启动开发"
主Agent: 
  1. 读取需求文档
  2. 查询项目看板获取历史上下文
  3. 确定变更名称
  4. 进入EXPLORE状态
  5. 调度Explore Agent执行/opsx:explore
```

**Step 2: Explore阶段**

```
Explore Agent执行:
  - /opsx:explore <topic>
  - 分析代码库现状
  - 输出需求分析文档(REQ-01)
  - 输出方案设计文档(DES-02)

主Agent:
  - 解析需求分析文档
  - 评估方案可行性
  - 决定推进至CREATE或回退
```

**Step 3: Create阶段**

```
Create Agent执行:
  - /opsx:ff <change-name>
  - 生成proposal.md, design.md, tasks.md, delta specs

主Agent:
  - 验证规划制品完整性
  - 检查proposal/specs/design/tasks是否就绪
  - 推进至GATE_REVIEW
```

**Step 4: Gate Review阶段**

```
Gate Review Agent执行:
  - 读取所有规划制品
  - 执行8维度审查skill
  - 输出gate_review.md

主Agent评估:
  - PASS → 推进至APPLY
  - CONDITIONAL_PASS → 判断条件是否可接受
  - BLOCKED → 回退至EXPLORE或CREATE
```

**Step 5: Apply阶段**

```
Apply Agent执行:
  - /opsx:apply
  - 按tasks.md逐项实现代码
  - 每次代码修改后执行compile skill
  - 编译失败则自动修复（最多3次）

主Agent:
  - 监控tasks进度（通过openspec status --change <name>）
  - 编译失败超过3次 → 汇报用户
  - 编译成功 → 推进至CODE_REVIEW
```

**Step 6: Code Review阶段**

```
Code Review Agent执行:
  - 读取代码diff
  - 执行代码审查skill
  - 输出code_review.md

主Agent评估:
  - PASS → 推进至TEST
  - MUST_FIX → 回退至APPLY
  - SUGGEST → 推进至TEST（建议项不阻塞）
```

**Step 7: Test阶段**

```
Test Agent执行:
  - 运行测试套件skill
  - 执行/opsx:verify（初步验证）
  - 输出test_report.md

主Agent:
  - 所有测试通过 → 推进至VERIFY
  - 有失败用例 → 回退至APPLY
```

**Step 8: Verify阶段**

```
Verify Agent执行:
  - /opsx:verify（完整验证）
  - 执行自定义验证脚本（如verify_all.ps1）
  - 输出verification_report.md

主Agent:
  - 0 FAIL → 推进至SYNC
  - 有FAIL → 回退至APPLY
```

**Step 9: Sync阶段**

```
Sync Agent执行:
  - /opsx:sync
  - 将delta specs合并到主规格库

主Agent:
  - 同步成功 → 推进至ARCHIVE
  - 同步冲突 → 人工介入
```

**Step 10: Archive阶段**

```
Archive Agent执行:
  - /opsx:archive
  - 变更目录移至archive
  
主Agent:
  - 更新项目看板（标记任务完成）
  - 记录变更摘要到项目历史
  - 输出最终交付报告
```

---

## 五、设计总结

该工作流设计的核心优势：

1. **协议标准化**：OpenSpec文档作为Agent间的统一通信协议，确保"仓库里的知识才是唯一的真相源头"，消除信息散落问题
2. **状态机驱动**：严格的状态跃迁规则（闸门阻塞/评审必改/测试缺陷强制回退），从系统层面避免了Agent"既当运动员又当裁判"的问题
3. **职责分离**：Explore Agent不碰代码生成，Apply Agent不碰需求分析——职责分离本身就是一种质量保障
4. **自动化验证闭环**：Rules → Skills → Scripts三层架构，能用机器检查的绝不依赖AI记忆
5. **错误恢复机制**：明确的回退路径和重试上限，避免无限循环
6. **跨会话记忆**：项目任务看板提供历史上下文，避免每个新需求"从零开始"

核心原则对齐Harness Engineering的理念：**Humans steer. Agents execute. 人掌舵，Agent干活。** 主Agent做调度决策、子Agent专注执行opsx命令和工具，OpenSpec文档贯穿全流程形成闭环，最终实现高质量、可复现、可审计的AI驱动开发。