# 闸门审查报告: add-list-view

**审查时间:** 2026-05-02
**审查结论:** BLOCKED (37/80)

## 审查概要

| 维度 | 状态 | 评分 | 说明 |
| --- | --- | --- | --- |
| 1. Scope Clarity | FAIL | 4/10 | 范围未明确定义 In/Out of Scope 边界 |
| 2. Requirement Integrity | FAIL | 2/10 | P0 需求覆盖不完整；排序排除项被违反 |
| 3. Design Feasibility | PASS | 8/10 | 技术方案可行 |
| 4. Architecture Alignment | PASS | 8/10 | 架构风格一致 |
| 5. Risk Assessment | FAIL | 4/10 | 遗漏关键风险 |
| 6. Task Completeness | FAIL | 5/10 | 缺少测试/持久化任务 |
| 7. Spec Compliance | FAIL | 5/10 | 规格与需求矛盾 |
| 8. Rollback Plan | FAIL | 1/10 | 无回滚方案 |

## 阻塞项

### B-001: 排序功能与已确认需求直接矛盾 (Critical)
- REQ-01 明确标记 [x] 不需要排序（P0）。但 design.md Goals 含 "column sorting"，specs 含 5 个排序场景，tasks 含 sortField/sortOrder 任务。
- **修复:** 从 design/specs/tasks 中移除所有排序功能，对齐 REQ-01。

### B-002: 卡片式列表与表格布局歧义 (Critical)
- REQ-01 确认"卡片式列表（非紧凑表格）"；DES-02 描述"内联渲染卡片内容"。但 design.md 写 "Table columns"，spec.md 写 "table format"。
- **修复:** 统一为卡片式列表，将 "Table columns" 改为 "Card fields"，"table format" 改为 "card-style list"。

### B-003: viewMode 持久化矛盾 (Critical)
- REQ-01 R7（P0）要求 localStorage 持久化。DES-02 包含持久化代码。但 design.md Risks 声明 "viewMode not persisted to localStorage for simplicity"。
- **修复:** 移除 design.md 中的错误声明，确认 viewMode 持久化。

## 改进建议

- S-001: 空状态消息不一致（"未找到匹配的卡片" vs "暂无卡片"）
- S-002: tasks.md 缺少测试任务
- S-003: tasks.md 缺少可折叠组任务（REQ-01 R9 P2）
- S-004: 缺少回滚方案
- S-005: spec.md 缺少持久化和向后兼容场景
