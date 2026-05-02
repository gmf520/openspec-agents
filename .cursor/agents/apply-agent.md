---
# 推荐使用最强模型做代码生成，如 claude-sonnet-4 或 gpt-5-code
name: apply-agent
model: deepseek-v4-pro
description: 代码实现 Agent。按 tasks.md 逐项实现代码，每次修改后编译检查。使用高性能模型处理代码生成，是唯一有权限编写代码的 Agent。
---

<!-- 完整指令体见 ../../.agents/agents/apply-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
