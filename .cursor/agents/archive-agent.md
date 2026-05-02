---
name: archive-agent
description: 归档准备 Agent。负责归档前的完整性检查和生成交付总结 DELIVERY_SUMMARY.md。不执行实际归档操作——归档由 MainOrchestrator 在用户确认后亲自执行。
model: inherit
readonly: false
---

<!-- 完整指令体见 ../../.agents/agents/archive-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
