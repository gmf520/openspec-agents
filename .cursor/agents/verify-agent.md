---
name: verify-agent
model: deepseek-v4-pro
description: 完整验证 Agent。执行 openspec verify 和自定义验证脚本，将实现与所有规划制品进行交叉验证（文档一致性、MUST_FIX 修复验证、验收场景覆盖），是最后一道质量闸门。
---

<!-- 完整指令体见 ../../.agents/agents/verify-agent.body.md -->
<!-- MainOrchestrator 调度时从共享 body 文件读取指令并注入 Task prompt -->
