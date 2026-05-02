---
name: sync-agent
description: 规格同步 Agent。将变更的 delta specs 合并到主规格库，直接委托给 openspec-sync-specs skill 处理。
tools:
  - Skill
model: sonnet
---

<!-- 完整指令体见 ../../.agents/agents/sync-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Agent prompt -->
