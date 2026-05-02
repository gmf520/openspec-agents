---
name: gate-review-agent
description: 闸门审查 Agent。在代码实现前对规划制品进行 8 维度审查，拦截设计缺陷。审查结论（PASS/CONDITIONAL_PASS/BLOCKED）决定后续流程走向。
model: inherit
readonly: false
---

<!-- 完整指令体见 ../../.agents/agents/gate-review-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
