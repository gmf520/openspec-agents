# 闸门审查报告: fix-kanban-card-move

**审查时间:** 2026-05-01 20:53 (UTC+8)
**审查结论:** CONDITIONAL_PASS

---

## 审查概要

| 维度 | 状态 | 评分 | 说明 |
| --- | --- | --- | --- |
| 1. Scope Clarity | ✅ | 9/10 | In/Out of Scope 定义清晰，变更范围严格控制在 Column.vue 内 |
| 2. Requirement Integrity | ✅ | 9/10 | 两个根本原因（computed setter 为空、onDragChange 不处理跨列）准确定位，验收标准可测 |
| 3. Design Feasibility | ✅ | 9/10 | 基于 vuedraggable 原生 @change 事件，方案可行；无新增依赖 |
| 4. Architecture Alignment | ✅ | 9/10 | 遵循 Vue 3 Composition API + Pinia 现有模式，不引入循环依赖 |
| 5. Risk Assessment | ✅ | 8/10 | 低风险识别充分，但 @change 事件顺序的缓解措施可更具体 |
| 6. Task Completeness | ⚠️ | 7/10 | 缺少 @change 事件 payload TypeScript 类型定义任务；验证任务未显式映射到 spec 场景 |
| 7. Spec Compliance | ✅ | 8/10 | Given-When-Then 覆盖正常/异常/边界场景；proposal 提及"无需 delta spec"与实际存在 spec 文件有微小不一致 |
| 8. Rollback Plan | ⚠️ | 7/10 | 无显式回滚方案文档（因无 DB 变更/无新依赖，实际风险极低） |
| **总评** | | **66/80** | |

---

## 条件项

### C-001: 补充 @change 事件 payload TypeScript 类型定义

- **维度:** 6. Task Completeness
- **严重程度:** Minor
- **描述:** design.md 中定义了 `AddedData`、`MovedData`、`RemovedData` 接口，但 tasks.md 中没有包含将这些类型定义提取为实际代码的任务。当前 tasks.md 2.2 只要求"重写 onDragChange"，未要求在 Vue SFC 的 `<script setup>` 中显式定义或导入这些类型。
- **条件:** 在 APPLY 阶段前，Create Agent 在 tasks.md 中追加一个子任务："在 Column.vue 或独立的 types 文件中定义 AddedData/MovedData/RemovedData 接口（或从 vuedraggable 导入）"，确保 onDragChange 参数有正确类型标注。

### C-002: 验证任务显式映射到 delta spec 场景

- **维度:** 6. Task Completeness
- **严重程度:** Minor
- **描述:** tasks.md 的验证部分（3.1-3.3）覆盖了核心功能，但未与 specs/kanban-board/spec.md 中的 7 个 Given-When-Then 场景建立显式映射。"Drag to invalid target"场景（spec 场景 5）完全未被验证任务提及。
- **条件:** 在 APPLY 阶段前，Create Agent 将 task 3 扩展为逐条映射 spec 场景，确保每个 Given-When-Then 都有对应的验证步骤。特别是新增一个子任务验证"拖拽到非列区域，卡片回到原位置"。

---

## 改进建议

### S-001: 修正 proposal.md 关于 delta spec 的陈述

- **维度:** 7. Spec Compliance
- **严重程度:** 低
- **描述:** proposal.md 的 Modified Capabilities 段落声称"本次为纯 bug 修复，原有需求不变，无需 delta spec"，但 `specs/kanban-board/spec.md` 已存在且包含 7 个 delta spec 场景。虽然 spec 文件内容本身正确，但 proposal 的描述与事实不一致。建议在 proposal 中删除或修改"无需 delta spec"的表述。
- **优先级:** 低

### S-002: 补充 @change 事件顺序的详细说明

- **维度:** 5. Risk Assessment
- **严重程度:** 低
- **描述:** design.md 提到"@change 事件在 added 和 removed 同时触发时可能顺序微妙"，但未提供具体场景分析。建议补充说明：跨列拖拽时，源列触发 `removed`、目标列触发 `added`，两个事件分别在不同组件实例的 handler 中处理；只有目标列的 `added` 调用 `store.moveCard`，源列的 `removed` 被设计忽略，此行为正确的前提是 `store.moveCard` 内部已处理源列的顺序更新。
- **优先级:** 低

---

## 详细分析

### 维度 1: Scope Clarity (9/10)

- ✅ In Scope（修复 Column.vue 的 cards computed 和 onDragChange）明确定义
- ✅ Out of Scope（不动 store 层、Card 组件、模板结构、视觉样式）清晰列出
- ✅ 边界条件已考虑：仅修改单个文件、无新增依赖
- 无越界变更

### 维度 2: Requirement Integrity (9/10)

- ✅ proposal 覆盖 P0 需求（修复跨列拖拽）
- ✅ REQ-01 准确定位了两个独立 bug：computed setter 为空函数、onDragChange 不处理跨列
- ✅ 4 条验收标准可测量、可测试

### 维度 3: Design Feasibility (9/10)

- ✅ 技术方案在 Vue 3 + vuedraggable 栈中完全可行
- ✅ `ref + watch` 替代 computed 以解决跨列场景下无法获取目标列 ID 的问题
- ✅ `@change` 事件的 added/moved 语义比数组长度比对更可靠
- ✅ 直接复用 `store.moveCard()`，避免重复逻辑
- 无新依赖引入

### 维度 4: Architecture Alignment (9/10)

- ✅ 方案延续 Vue 3 Composition API 模式
- ✅ 直接调用 Pinia store 符合现有架构约定
- ✅ 无循环依赖
- ✅ 数据流清晰：用户操作 → @change 事件 → store.moveCard → 视图响应式更新

### 维度 5: Risk Assessment (8/10)

- ✅ 风险已识别：@change 事件顺序、vuedraggable 版本兼容性
- ⚠️ 风险缓解措施可更具体——建议补充跨列拖拽的完整事件流分析

### 维度 6: Task Completeness (7/10)

- ✅ 任务覆盖了理解定位（1.x）、实现修复（2.x）、验证（3.x）三大阶段
- ✅ 任务顺序合理（理解 → 实现 → 验证）
- ❌ **C-001**: 缺少 @change 事件 payload TypeScript 类型定义任务
- ❌ **C-002**: 验证任务未显式映射到 spec 场景
- 测试任务覆盖了主要功能（跨列、同列、刷新），但未覆盖 spec 中的"拖拽到无效目标"场景

### 维度 7: Spec Compliance (8/10)

- ✅ 7 个 Given-When-Then 场景覆盖了正常（跨列有数据/空列、同列重排序）、边界（拖回原列、拖到无效目标）、数据持久化（刷新后）场景
- ✅ 场景设计合理、可自动化测试
- ⚠️ proposal.md 声称"无需 delta spec"与实际存在 spec 文件不一致

### 维度 8: Rollback Plan (7/10)

- ✅ 无 DB 迁移、无 API 变更、无新依赖——回滚操作仅需 `git revert`
- ❌ 所有文档中均无显式的回滚方案描述
- ⚠️ 考虑到变更范围极小（单个组件），此维度不构成阻塞

---

## 下一步行动

**结论: CONDITIONAL_PASS**

→ MainOrchestrator 必须将以下条件项传给 Create Agent 修复：
  - **C-001**: 补充 @change 事件 payload 的 TypeScript 类型定义任务
  - **C-002**: 验证任务显式映射到 delta spec 场景

→ Create Agent 修复完毕后，评估是否需要二次 Gate Review（由于均为 Minor 级别条件，此变更不要求二次审查）

→ 严禁 MainOrchestrator 自行修改 proposal/design/tasks/specs 等规划制品
