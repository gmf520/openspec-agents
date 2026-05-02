# 开发记录: add-list-view

**开始时间:** 2026-05-02T23:00:00
**结束时间:** 2026-05-02T23:23:30
**编译结果:** PASS
**测试结果:** 11/11 PASS

---

## 任务完成情况

| 任务ID | 描述 | 状态 | 修改文件 | 编译结果 |
| ------ | ---- | ---- | -------- | -------- |
| 1.1 | Add viewMode ref to todo store (default "board") | X | src/types/index.ts, src/stores/todo.ts | PASS |
| 1.2 | Add setViewMode action to store | X | src/stores/todo.ts | PASS |
| 1.3 | Add viewMode to localStorage persist/restore | X | src/stores/todo.ts | PASS |
| 2.1 | Create ListView.vue with card-style list layout | X | src/components/ListView.vue | PASS |
| 2.2 | Group cards by column with collapsible group headers | X | src/components/ListView.vue | PASS |
| 2.3 | Priority badge display | X | src/components/ListView.vue | PASS |
| 2.4 | Tag display with colored labels | X | src/components/ListView.vue | PASS |
| 2.5 | Due date formatting with overdue highlighting | X | src/components/ListView.vue | PASS |
| 2.6 | Inline complete checkbox | X | src/components/ListView.vue | PASS |
| 2.7 | Edit/delete buttons per row | X | src/components/ListView.vue | PASS |
| 2.8 | Empty state display | X | src/components/ListView.vue | PASS |
| 3.1 | View mode toggle buttons in App.vue header | X | src/App.vue | PASS |
| 3.2 | Conditional render Board.vue or ListView.vue | X | src/App.vue | PASS |
| 3.3 | Verify search/filter state shared between views | X | (verification only) | PASS |
| 3.4 | Verify CardModal edit flows from list view | X | (verification only) | PASS |
| 4.1 | Unit test: viewMode state and setViewMode | X | src/__tests__/todo-store.test.ts | PASS |
| 4.2 | Unit test: viewMode localStorage persist/restore | X | src/__tests__/todo-store.test.ts | PASS |
| 4.3 | Unit test: backward compatibility | X | src/__tests__/todo-store.test.ts | PASS |
| 4.4 | Component test: ListView grouped rendering | X | src/__tests__/ListView.test.ts | PASS |
| 4.5 | Component test: ListView empty state | X | src/__tests__/ListView.test.ts | PASS |
| 4.6 | Component test: view toggle | X | src/__tests__/App.test.ts | PASS |

---

## 变更清单

### 新增文件

- `src/components/ListView.vue`: 核心新增组件，card-style 列表视图，包含按列分组、可折叠组头、优先级徽章、标签显示、截止日期、内联完成复选框、编辑/删除按钮、空状态提示
- `vitest.config.ts`: Vitest 测试框架配置，jsdom 环境，全局 API
- `src/__tests__/todo-store.test.ts`: 5 个单元测试，覆盖 viewMode 状态、setViewMode 动作、localStorage 持久化与恢复、向后兼容
- `src/__tests__/ListView.test.ts`: 3 个组件测试，覆盖按列分组渲染、空状态显示、有匹配卡片时隐藏空状态
- `src/__tests__/App.test.ts`: 3 个组件测试，覆盖默认看板视图、切换到列表视图、切换回看板视图

### 修改文件

- `src/types/index.ts`: AppState 接口新增 `viewMode: 'board' | 'list'` 字段
- `src/stores/todo.ts`: 新增 `viewMode` ref（默认 "board"）、`setViewMode` action；`persist()` 和 `loadFromStorage()` 增加 viewMode 持久化与恢复（向后兼容）；`exportData()` 包含 viewMode
- `src/App.vue`: 导入 ListView.vue；header 新增视图切换按钮组（带样式）；Board/ListView 条件渲染；noResults 仅在 board 视图显示；`handleExport()` 包含 viewMode

---

## 编译历史

| 时间 | 任务 | 结果 | 错误数 | 说明 |
| ---- | ---- | ---- | ------ | ---- |
| 23:01 | Phase 1 | PASS | 0 | viewMode store 变更编译通过 |
| 23:10 | Phase 2 | PASS | 0 | ListView.vue 创建编译通过 |
| 23:15 | Phase 3 | PASS | 0 | App.vue 集成编译通过 |
| 23:23 | Phase 4 | PASS | 0 | 测试文件和配置编译通过，11/11 测试通过 |

---

## 问题记录

无。所有任务一次通过，无编译错误或测试失败。

---

## Gate 条件验证

### C-001: viewMode 命名统一 "kanban" -> "board"
- 已使用 `"board"` 作为 default 字面值，代码中统一使用 `'board' | 'list'` 类型
- tasks.md 中 task 1.1 的默认值也从 "kanban" 修正为 "board"

### C-002: 补充卡片字段列表
- ListView.vue 复用 Card.vue 的全部信息展示: title, description, priority, tags, dueDate, createdAt, completed 均已包含
