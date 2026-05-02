---
name: gate-review-agent
description: 闸门审查 Agent。在代码实现前审查所有规划制品，执行 8 维度质量门禁检查，输出 PASS/CONDITIONAL_PASS/BLOCKED 结论。
tools:
  - Read
model: sonnet
---

<!-- 完整指令体见 ../../.agents/agents/gate-review-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Agent prompt -->
