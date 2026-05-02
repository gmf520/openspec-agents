---
name: test-agent
description: 测试验证 Agent。运行测试套件并验证代码功能正确性，对照 delta specs 的 Given-When-Then 场景逐条验证，输出 PASS/FAIL 结论。
tools:
  - Read
  - Write
  - Bash
  - Grep
model: haiku
---

<!-- 完整指令体见 ../../.agents/agents/test-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Agent prompt -->
