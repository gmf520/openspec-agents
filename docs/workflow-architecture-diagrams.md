# 多智能体工作流设计 — Mermaid 图示

> 基于 `.cursor/commands/opsx-workflow.md` 与 `workflow/state-machine.yaml`

---

## 1. 架构图 — 多智能体工作流总览

```mermaid
graph TB
    subgraph User
        CMD["/opsx:workflow<br/>change-name + requirement"]
    end

    subgraph MainOrchestrator["🧠 MainOrchestrator（主调度器）"]
        SM["状态机引擎<br/>State Machine"]
        PB["项目看板<br/>project-board.yaml"]
        RETRY["重试控制器<br/>max_retries: 3"]
        ERR["错误处理器<br/>rollback / report_to_human"]
    end

    subgraph EXPLORE["🔍 EXPLORE 阶段<br/>(MainOrchestrator 直接执行)"]
        E1["REQ-01<br/>需求分析"]
        E2["DES-02<br/>方案设计"]
    end

    subgraph SubAgents["🤖 子 Agent（通过 Task 工具调度）"]
        CA["Create Agent<br/>生成规划制品"]
        GA["Gate Review Agent<br/>8 维度闸门审查"]
        AA["Apply Agent<br/>代码实现"]
        CRA["Code Review Agent<br/>代码评审"]
        TA["Test Agent<br/>测试验证"]
        VA["Verify Agent<br/>完整验证"]
        SA["Sync Agent<br/>规格同步"]
        ARA["Archive Agent<br/>归档"]
    end

    subgraph Artifacts["📦 产出制品"]
        ART1["proposal.md<br/>design.md<br/>tasks.md<br/>specs/"]
        ART2["GATE-03<br/>gate_review.md"]
        ART3["DEV-04<br/>development.md"]
        ART4["CR-05<br/>code_review.md"]
        ART5["TEST-06<br/>test_report.md"]
        ART6["VERIFY-07<br/>verification_report.md"]
        ART7["openspec/specs/"]
        ART8["archive/<change-name>/"]
    end

    subgraph GateDimensions["🚦 8 维度闸门"]
        G1["Scope Clarity"]
        G2["Requirement Integrity"]
        G3["Design Feasibility"]
        G4["Architecture Alignment"]
        G5["Risk Assessment"]
        G6["Task Completeness"]
        G7["Spec Compliance"]
        G8["Rollback Plan"]
    end

    CMD --> SM
    SM --> PB
    SM --> EXPLORE
    EXPLORE --> CA
    CA --> ART1
    ART1 --> GA
    GA --> GateDimensions
    GateDimensions --> ART2
    ART2 --> AA
    AA --> ART3
    ART3 --> CRA
    CRA --> ART4
    ART4 --> TA
    TA --> ART5
    ART5 --> VA
    VA --> ART6
    ART6 --> SA
    SA --> ART7
    ART7 --> ARA
    ARA --> ART8

    SM -.-> RETRY
    SM -.-> ERR
```

---

## 2. 类图 — 核心实体与关系

```mermaid
classDiagram
    class MainOrchestrator {
        +String changeName
        +String currentState
        +startWorkflow(changeName, requirement)
        +transitionTo(targetState)
        +handleError(errorType)
        +updateProjectBoard()
    }

    class State {
        +String name
        +String description
        +String executor
        +String skill
        +String[] artifacts
        +Transition[] transitions
        +int maxRetries
        +boolean terminal
        +enter()
        +exit()
        +onError()
    }

    class Transition {
        +String target
        +String condition
        +evaluate(context) boolean
    }

    class Agent {
        <<abstract>>
        +String name
        +String role
        +String skillRef
        +Artifact[] outputArtifacts
        +execute(context)
        +validateInput()
        +generateOutput()
    }

    class ExploreAgent {
        +analyzeRequirement()
        +designSolution()
        +selfCheck()
    }

    class CreateAgent {
        +generateProposal()
        +generateDesign()
        +generateTasks()
        +generateSpecs()
    }

    class GateReviewAgent {
        +String conclusion
        +int totalScore
        +DimensionResult[] dimensionResults
        +reviewAllDimensions()
        +determineConclusion()
    }

    class ApplyAgent {
        +int currentTaskIndex
        +int compileRetryCount
        +executeTask(task)
        +compileCheck()
        +autoFix()
    }

    class CodeReviewAgent {
        +String[] mustFixItems
        +String[] suggestions
        +reviewCode()
        +determineOutcome()
    }

    class TestAgent {
        +TestResult[] results
        +runTests()
        +classifyDefects()
    }

    class VerifyAgent {
        +String[] failures
        +verifyArtifacts()
        +checkConsistency()
    }

    class SyncAgent {
        +syncSpecs()
        +resolveConflicts()
    }

    class ArchiveAgent {
        +archive()
        +generateSummary()
    }

    class Skill {
        +String name
        +String description
        +String metadata
        +Guardrail[] guardrails
        +getInstructions() String
    }

    class Artifact {
        +String name
        +String path
        +String type
        +boolean required
        +validate()
    }

    class GateDimension {
        +String name
        +String description
        +String status
        +int score
        +String[] checkItems
        +evaluate(artifacts) DimensionResult
    }

    class DimensionResult {
        +String status
        +int score
        +String note
    }

    class ProjectBoard {
        +ActiveChange[] activeChanges
        +CompletedChange[] completedChanges
        +updateStatus(changeName, status)
        +incrementRetry(changeName, phase)
        +markComplete(changeName)
    }

    class ErrorHandler {
        +handleCompileFailure()
        +handleGateBlocked()
        +handleReviewMustFix()
        +handleTestBlocking()
        +handleVerifyFail()
        +handleSyncConflict()
    }

    MainOrchestrator "1" --> "1" State : current state
    MainOrchestrator "1" --> "1" ProjectBoard : manages
    MainOrchestrator "1" --> "1" ErrorHandler : uses
    State "1" --> "*" Transition : has
    State "1" --> "1" Agent : executor
    Agent "1" --> "1" Skill : references
    Agent "1" --> "*" Artifact : produces
    GateReviewAgent "1" --> "8" GateDimension : evaluates
    GateDimension "1" --> "1" DimensionResult : produces
    Agent <|-- ExploreAgent
    Agent <|-- CreateAgent
    Agent <|-- GateReviewAgent
    Agent <|-- ApplyAgent
    Agent <|-- CodeReviewAgent
    Agent <|-- TestAgent
    Agent <|-- VerifyAgent
    Agent <|-- SyncAgent
    Agent <|-- ArchiveAgent
```

---

## 3. 序列图 — 完整工作流执行时序

```mermaid
sequenceDiagram
    actor User
    participant MO as MainOrchestrator
    participant SM as StateMachine
    participant PB as ProjectBoard
    participant EA as Explore Agent<br/>(MO 直接执行)
    participant CA as Create Agent<br/>(Task)
    participant GA as Gate Review Agent<br/>(Task)
    participant AA as Apply Agent<br/>(Task)
    participant CRA as Code Review Agent<br/>(Task)
    participant TA as Test Agent<br/>(Task)
    participant VA as Verify Agent<br/>(Task)
    participant SA as Sync Agent<br/>(Task)
    participant ARA as Archive Agent<br/>(Task)

    User->>MO: /opsx:workflow add-dark-mode "需求描述"
    MO->>MO: 解析参数
    MO->>PB: openspec list --json（检查重复）
    PB-->>MO: 无同名变更
    MO->>PB: 初始化 project-board.yaml
    MO->>SM: 进入 EXPLORE

    rect rgb(230, 245, 255)
        Note over MO,EA: EXPLORE 阶段（主 Agent 直接交互）
        MO->>EA: 读取需求 + 调研代码库
        EA->>EA: 逐条拆解，标注模糊点
        EA-->>User: 展示多义性，请求澄清
        User-->>EA: 确认/补充
        EA->>EA: 生成 REQ-01_requirement_analysis.md
        EA->>EA: 对比方案 → 生成 DES-02_solution_design.md
        EA->>EA: 自查产出完整性
        EA-->>User: 展示方案，请求确认
        User-->>MO: ✅ 确认通过
    end

    MO->>SM: 转换 → CREATE
    MO->>PB: 更新状态

    rect rgb(255, 245, 230)
        Note over CA: CREATE 阶段
        MO->>CA: Task 工具调度（run_in_background）
        CA->>CA: 读取 REQ-01 + DES-02
        CA->>CA: 生成 proposal.md
        CA->>CA: 生成 design.md
        CA->>CA: 生成 tasks.md
        CA->>CA: 生成 specs/
        CA-->>MO: ✅ 全部制品就绪
    end

    MO->>SM: 转换 → GATE_REVIEW
    MO->>PB: 更新状态 + incrementRetry

    rect rgb(255, 230, 230)
        Note over GA: GATE_REVIEW 阶段
        MO->>GA: Task 工具调度（run_in_background）
        GA->>GA: 读取全部规划制品
        GA->>GA: 8 维度逐项审查
        alt 审查通过 (PASS)
            GA-->>MO: ✅ 结论 PASS
        else 条件通过 (CONDITIONAL_PASS)
            GA-->>MO: ⚠️ 结论 CONDITIONAL_PASS（附条件项）
            MO->>MO: 评估是否可以进入 APPLY
        else 阻塞 (BLOCKED)
            GA-->>MO: ❌ 结论 BLOCKED（附阻塞原因）
            MO->>SM: 回退 EXPLORE / CREATE
        end
    end

    MO->>SM: 转换 → APPLY
    MO->>PB: 更新状态

    rect rgb(230, 255, 230)
        Note over AA: APPLY 阶段
        MO->>AA: Task 工具调度（run_in_background）
        loop 每个任务
            AA->>AA: 执行 Task X.Y
            AA->>AA: 编译检查
            alt 编译通过
                AA->>AA: ✅ 标记任务完成
            else 编译失败
                AA->>AA: 自动修复（最多 3 次）
                alt 修复成功
                    AA->>AA: ✅ 标记任务完成
                else 3 次失败
                    AA->>AA: ❌ 记录 Issue，上报
                end
            end
        end
        AA->>AA: 生成 DEV-04_development.md
        AA-->>MO: ✅ 全部任务完成 + 编译通过
    end

    MO->>SM: 转换 → CODE_REVIEW
    MO->>PB: 更新状态

    rect rgb(240, 230, 255)
        Note over CRA: CODE_REVIEW 阶段
        MO->>CRA: Task 工具调度（run_in_background）
        CRA->>CRA: 审查全部代码变更
        CRA->>CRA: 生成 CR-05_code_review.md
        alt 通过 / 仅建议
            CRA-->>MO: ✅ 通过
        else 有 must_fix
            CRA-->>MO: ❌ must_fix 项 → 回退 APPLY
            MO->>SM: 回退 APPLY
        end
    end

    MO->>SM: 转换 → TEST
    MO->>PB: 更新状态

    rect rgb(255, 255, 230)
        Note over TA: TEST 阶段
        MO->>TA: Task 工具调度（run_in_background）
        TA->>TA: 运行测试
        TA->>TA: 生成 TEST-06_test_report.md
        alt 全部通过
            TA-->>MO: ✅ 所有测试通过
        else 有阻塞性缺陷
            TA-->>MO: ❌ blocking defect → 回退 APPLY
            MO->>SM: 回退 APPLY
        end
    end

    MO->>SM: 转换 → VERIFY
    MO->>PB: 更新状态

    rect rgb(255, 235, 220)
        Note over VA: VERIFY 阶段
        MO->>VA: Task 工具调度（run_in_background）
        VA->>VA: 完整验证（制品一致性）
        VA->>VA: 生成 VERIFY-07_verification_report.md
        alt 零失败
            VA-->>MO: ✅ 验证通过
        else 有失败项
            VA-->>MO: ❌ has_fail → 回退 APPLY
            MO->>SM: 回退 APPLY
        end
    end

    MO->>SM: 转换 → SYNC
    MO->>PB: 更新状态

    rect rgb(220, 240, 240)
        Note over SA: SYNC 阶段
        MO->>SA: Task 工具调度（run_in_background）
        SA->>SA: 增量规格 → 主规格同步
        alt 同步成功
            SA-->>MO: ✅ 同步完成
        else 冲突
            SA-->>MO: ❌ sync_conflict → 回退 APPLY
            MO->>SM: 回退 APPLY
        end
    end

    MO->>SM: 转换 → ARCHIVE
    MO->>PB: 更新状态

    rect rgb(240, 240, 250)
        Note over ARA: ARCHIVE 阶段
        MO->>ARA: Task 工具调度（run_in_background）
        ARA->>ARA: 归档到 archive/<change-name>/
        ARA->>ARA: 生成交付总结 + 更新看板
        ARA-->>MO: ✅ 归档完成
    end

    MO->>SM: 转换 → COMPLETE
    MO->>PB: markComplete
    MO-->>User: 🎉 工作流完成: <change-name>
```

---

## 4. 甘特图 — 阶段时间线与依赖

```mermaid
gantt
    title 多智能体工作流 — 阶段执行甘特图
    dateFormat  HH:mm
    axisFormat  %H:%M

    section EXPLORE（主Agent）
    读取需求 + 调研代码库           :e1, 00:00, 10m
    需求分析 → REQ-01               :e2, after e1, 15m
    方案设计 → DES-02               :e3, after e2, 20m
    用户确认                         :milestone, after e3, 0m

    section CREATE（Create Agent）
    生成 proposal.md + design.md    :c1, after e3, 15m
    生成 tasks.md + specs/          :c2, after c1, 15m
    制品就绪检查                     :milestone, after c2, 0m

    section GATE_REVIEW（Gate Review Agent）
    维度 1-2: Scope + Requirement   :g1, after c2, 5m
    维度 3-4: Design + Architecture :g2, after g1, 5m
    维度 5-6: Risk + Task           :g3, after g2, 5m
    维度 7-8: Spec + Rollback       :g4, after g3, 5m
    审查结论                         :milestone, after g4, 0m

    section APPLY（Apply Agent）
    Task 1.1 实现                    :a1, after g4, 10m
    Task 1.2 实现                    :a2, after a1, 10m
    Task 2.1 实现                    :a3, after a2, 15m
    Task 2.2 实现                    :a4, after a3, 10m
    编译检查 + 开发记录              :a5, after a4, 5m

    section CODE_REVIEW（Code Review Agent）
    代码审查                         :cr1, after a5, 15m
    审查结论                         :milestone, after cr1, 0m

    section TEST（Test Agent）
    运行测试套件                     :t1, after cr1, 20m
    测试报告                         :milestone, after t1, 0m

    section VERIFY（Verify Agent）
    制品一致性验证                   :v1, after t1, 15m
    验证报告                         :milestone, after v1, 0m

    section SYNC（Sync Agent）
    规格同步                         :s1, after v1, 5m

    section ARCHIVE（Archive Agent）
    归档 + 交付总结                  :ar1, after s1, 5m
    完成                             :milestone, after ar1, 0m
```

> **说明**: 以上时长仅为示意，实际耗时取决于变更规模和复杂度。状态机支持各阶段回退（如 Apply → Code Review → Apply），回退时对应阶段会重新执行，最多重试 3 次。

---

## 附：状态转换图

```mermaid
stateDiagram-v2
    [*] --> EXPLORE : 用户发起 /opsx:workflow

    EXPLORE --> EXPLORE : 需要更多讨论<br/>(need_more_discussion)
    EXPLORE --> CREATE : 用户确认产出<br/>(user_confirmed)

    CREATE --> CREATE : 制品不完整<br/>(artifacts_incomplete)
    CREATE --> GATE_REVIEW : 全部制品就绪<br/>(all_artifacts_ready)

    GATE_REVIEW --> APPLY : 审核通过<br/>(gate_pass)
    GATE_REVIEW --> CREATE : 有条件通过<br/>(gate_conditional_pass)
    GATE_REVIEW --> EXPLORE : 阻塞→需求不清<br/>(gate_blocked)

    APPLY --> APPLY : 编译失败→重试<br/>(compile_failed, max 3次)
    APPLY --> CODE_REVIEW : 完成+编译通过<br/>(all_tasks_done_and_compile_pass)

    CODE_REVIEW --> TEST : 通过/仅建议<br/>(review_pass_or_suggest_only)
    CODE_REVIEW --> APPLY : 有必须修复项<br/>(has_must_fix)

    TEST --> VERIFY : 全部测试通过<br/>(all_tests_pass)
    TEST --> APPLY : 阻塞性缺陷<br/>(has_blocking_defect)

    VERIFY --> SYNC : 零失败<br/>(zero_fail)
    VERIFY --> APPLY : 有失败项<br/>(has_fail)

    SYNC --> ARCHIVE : 同步成功<br/>(sync_success)
    SYNC --> APPLY : 同步冲突<br/>(sync_conflict)

    ARCHIVE --> COMPLETE : 归档成功<br/>(archive_success)
    ARCHIVE --> ARCHIVE : 重试 (max 3次)

    COMPLETE --> [*] : 工作流结束
```

---

## 附：错误处理回退路径

```mermaid
flowchart LR
    subgraph 正常流程
        EX["EXPLORE"] --> CR["CREATE"] --> GR["GATE_REVIEW"] --> AP["APPLY"] --> CREV["CODE_REVIEW"] --> TE["TEST"] --> VE["VERIFY"] --> SY["SYNC"] --> AR["ARCHIVE"] --> CO["COMPLETE"]
    end

    subgraph 错误回退
        GR -- "gate_blocked" --> EX
        GR -- "gate_conditional_pass" --> CR
        CREV -- "has_must_fix" --> AP
        TE -- "has_blocking_defect" --> AP
        VE -- "has_fail" --> AP
        SY -- "sync_conflict" --> AP
        AP -- "compile_failed (≤3次)" --> AP
        AP -- "compile_failed (>3次)" --> ERR["上报人工处理"]
    end

    style 正常流程 fill:#e8f5e9,stroke:#4caf50
    style 错误回退 fill:#fff3e0,stroke:#ff9800
    style ERR fill:#ffcdd2,stroke:#f44336
```
