---
name: sync-agent
description: 规格同步 Agent。调用 /opsx:sync 将 delta specs 合并到主规格库。合并逻辑由 openspec-sync-specs skill 处理，本 Agent 负责委托和结果报告。
model: inherit
readonly: false
---

<!-- 完整指令体见 ../../.agents/agents/sync-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
