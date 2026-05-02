---
# 推荐使用与 apply-agent 不同的模型，避免同模型自审盲区
name: code-review-agent
model: deepseek-v4-pro
description: 代码评审 Agent。对 Apply Agent 的代码变更进行全面审查（正确性/安全性/性能/可维护性/一致性/测试覆盖/任务完成度/类型安全），发现自审盲区。
---

<!-- 完整指令体见 ../../.agents/agents/code-review-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
