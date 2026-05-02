---
name: verify-agent
description: 完整验证 Agent。将实现与所有规划制品进行交叉验证，是最后一道质量闸门，确保所有东西都正确且一致，输出 PASS/FAIL 结论。
tools:
  - Read
  - Write
  - Bash
model: opus
---

<!-- 完整指令体见 ../../.agents/agents/verify-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Agent prompt -->
