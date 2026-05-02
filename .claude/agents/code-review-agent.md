---
name: code-review-agent
description: 代码评审 Agent。审查 Apply Agent 产出的所有代码变更，检查正确性、安全性、性能、可维护性等 8 个维度，输出 PASS/MUST_FIX/SUGGEST 结论。
tools:
  - Read
  - Bash
model: opus
---

<!-- 完整指令体见 ../../.agents/agents/code-review-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Agent prompt -->
