# CR-05 代码审查报告: create-todos-app

## 重审记录 (2026-05-01T11:31)

**重审类型:** 第 2 次审查（仅验证 MUST_FIX 修复）  
**审查范围:** 仅 MF-01 / MF-02 / MF-03 相关 3 个文件 + 编译验证  
**修复基线:** `DEV-04_development.md` 末尾修复记录

### MF-01: 自定义标签不持久化 → ✅ 已修复

**文件:** `src/stores/todo.ts`, `src/components/CardModal.vue`

| 检查项 | 状态 | 位置 |
|--------|------|------|
| 新增 `addTag(name, color)` action | ✅ | `todo.ts` L198-207 |
| `addTag` 内部调用 `persist()` 保存到 localStorage | ✅ | `todo.ts` L205 |
| `addTag` 在 store return 中导出 | ✅ | `todo.ts` L280 |
| `CardModal.vue` `createNewTag()` 改用 `store.addTag()` | ✅ | `CardModal.vue` L86 |

### MF-02: JSON 导入缺少覆盖确认提示 → ✅ 已修复

**文件:** `src/App.vue`

| 检查项 | 状态 | 位置 |
|--------|------|------|
| `store.importData(file)` 前添加 `confirm()` 确认对话框 | ✅ | `App.vue` L69 |
| 用户取消时 `return` 不执行导入 | ✅ | `App.vue` L69 |

### MF-03: vuedraggable 事件参数使用 `any` 类型 → ✅ 已修复

**文件:** `src/components/Board.vue`, `src/components/Column.vue`

| 检查项 | 状态 | 位置 |
|--------|------|------|
| `Board.vue` 定义 `DragChangeEvent` 接口 | ✅ | `Board.vue` L5-9 |
| `Board.vue` `onCardMoved` 签名改用 `DragChangeEvent` | ✅ | `Board.vue` L18 |
| `Column.vue` 定义 `DragChangeEvent` 接口 | ✅ | `Column.vue` L8-19 |
| `Column.vue` emit 类型定义改用 `DragChangeEvent` | ✅ | `Column.vue` L29 |
| `Column.vue` `onDragChange` 签名改用 `DragChangeEvent` | ✅ | `Column.vue` L63 |
| 不再有 `any` 类型 | ✅ | 全局搜索确认 |

### 编译验证: ✅ 通过

```
npx vue-tsc --noEmit → exit code 0, 无错误
```

### 重审结论: ✅ PASS — 全部 3 项 MUST_FIX 已正确修复

MF-01/MF-02/MF-03 三项均已按修复方案正确实施，编译通过，无残留 `any` 类型。推进至 **TEST** 阶段。

---

## 首次审查记录

**审查时间:** 2026-05-01T11:06:00+08:00  
**审查范围:** `create-todos-app/src/` 下全部 13 个源文件  
**审查基线:** `proposal.md` / `design.md` / `tasks.md` / `DEV-04_development.md`

---

## 评审概要表

| 维度 | 评分 | 说明 |
|------|------|------|
| 1. 正确性 | ⚠️ 7/10 | 自定义标签不持久化（严重 Bug）；toggleComplete 双重 persist |
| 2. 安全性 | ✅ 9/10 | 无 XSS 漏洞，Vue 默认转义安全；localStorage 校验可进一步加强 |
| 3. 性能 | ⚠️ 7/10 | getCardsByColumn 无缓存，每次渲染全部列重新计算；reorderColumn O(n²) |
| 4. 可维护性 | ✅ 8/10 | 代码结构清晰，CSS 变量体系良好；缺少 JSDoc，模板内联数据 |
| 5. 一致性 | ✅ 8/10 | 命名规范统一；错误处理有 alert 和 return object 两种模式 |
| 6. 测试覆盖 | ❌ 3/10 | 0 个自动化测试，全部依赖手动测试 |
| 7. 任务完成度 | ⚠️ 8/10 | 40/42 任务完整；任务 9.2 缺少导入确认提示；任务 3.5 行为有偏差 |
| 8. 编译与类型安全 | ⚠️ 7/10 | vue-tsc 通过，但 3 处使用 `any` 绕过类型检查 |

**总体结论:** 代码架构与 design.md 高度吻合，主要功能实现完整。存在 **3 个 MUST_FIX 项**（1 个严重 Bug + 2 个功能缺失/类型安全缺陷）和 **5 个 SUGGEST 项**。MUST_FIX 必须在进入 TEST 阶段前修复。

---

## MUST_FIX 项

### MF-01: 自定义标签不持久化（严重 Bug）

- **文件:** `src/components/CardModal.vue` 第 84-95 行
- **严重程度:** 🔴 严重
- **问题描述:** `createNewTag()` 直接操作 `store.tags.push(newTag)`，但 `persist()` 是 store 内部的私有函数，未被导出。自定义标签创建后不会被保存到 localStorage，页面刷新后丢失。

```84:95:d:\Temp\openspec-agents\create-todos-app\src\components\CardModal.vue
function createNewTag() {
  if (!newTagName.value.trim()) return
  const newTag: Tag = {
    id: 'custom-' + Date.now(),
    name: newTagName.value.trim(),
    color: newTagColor.value,
  }
  store.tags.push(newTag)
  selectedTags.value = [...selectedTags.value, newTag]
  newTagName.value = ''
  showNewTag.value = false
}
```

**修复方案:** 在 store 中导出 `addTag` action，将持久化逻辑封装在 action 内。

在 `src/stores/todo.ts` 中添加：

```typescript
function addTag(name: string, color: string): Tag {
  const tag: Tag = {
    id: 'custom-' + Date.now(),
    name: name.trim(),
    color,
  }
  tags.value.push(tag)
  persist()
  return tag
}
```

并在 store return 中导出 `addTag`。然后修改 `CardModal.vue`：

```typescript
function createNewTag() {
  if (!newTagName.value.trim()) return
  const newTag = store.addTag(newTagName.value.trim(), newTagColor.value)
  selectedTags.value = [...selectedTags.value, newTag]
  newTagName.value = ''
  showNewTag.value = false
}
```

---

### MF-02: JSON 导入缺少覆盖确认提示

- **文件:** `src/App.vue` 第 61-76 行
- **严重程度:** 🟡 高
- **问题描述:** tasks.md 任务 9.2 明确要求"确认覆盖提示"，但 `handleImportClick()` 在读取文件后直接调用 `store.importData(file)` 覆盖所有数据，未弹出确认对话框。用户可能误操作导致数据丢失。

```61:76:d:\Temp\openspec-agents\create-todos-app\src\App.vue
function handleImportClick() {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = '.json'
  input.onchange = async (e: Event) => {
    const target = e.target as HTMLInputElement
    const file = target.files?.[0]
    if (file) {
      const result = await store.importData(file)
      if (!result.success) {
        alert(result.error)
      }
    }
  }
  input.click()
}
```

**修复方案:** 在 `store.importData(file)` 调用前添加 `confirm()`：

```typescript
input.onchange = async (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (file) {
    if (!confirm('导入数据将覆盖当前所有数据，是否继续？')) return
    const result = await store.importData(file)
    if (!result.success) {
      alert(result.error)
    }
  }
}
```

---

### MF-03: vuedraggable 事件参数使用 `any` 绕过类型检查

- **文件:** 
  - `src/components/Board.vue` 第 12 行 (`function onCardMoved(evt: any)`)
  - `src/components/Column.vue` 第 50 行 (`function onDragChange(evt: any)`)
  - `src/components/Board.vue` 第 8 行 (`'card-moved': [evt: any]`)
  - `src/components/Column.vue` 第 16 行 (`'card-moved': [evt: any]`)
- **严重程度:** 🟡 高
- **问题描述:** 4 处使用 `any` 类型，完全绕过了 TypeScript 类型检查。vuedraggable 提供了类型定义（`vuedraggable@next`），应使用正确的类型。

**修复方案:** vuedraggable v4 的 `@change` 事件参数类型可从库中导入。实际只需要 `item`（HTMLElement）、`to`（HTMLElement）、`newIndex`（number）三个字段。建议定义局部接口：

在需要使用的组件中添加：

```typescript
interface DragChangeEvent {
  item?: HTMLElement
  to?: HTMLElement
  newIndex?: number
}
```

然后替换所有 `any`：

```typescript
// Board.vue
function onCardMoved(evt: DragChangeEvent) {
  const cardId = evt.item?.dataset?.cardId
  const toColumnId = evt.to?.dataset?.columnId
  if (cardId && toColumnId) {
    store.moveCard(cardId, toColumnId, evt.newIndex)
  }
}
```

同时在 Column.vue 的 emit 定义中：

```typescript
const emit = defineEmits<{
  'create-card': []
  'edit-card': [card: TodoCard]
  'card-moved': [evt: DragChangeEvent]
}>()
```

---

## SUGGEST 项

### SG-01: toggleComplete 双重 persist 调用

- **文件:** `src/stores/todo.ts` 第 129-146 行
- **影响:** 低（功能正确，但有两次 localStorage 写入）
- **说明:** `toggleComplete` 内部依次调用 `moveCard()` → `updateCard()`，两者各自触发 `persist()`，导致一次用户操作产生两次 localStorage.setItem()。建议合并为一次写入或将 `completed` 状态更新合并到 `moveCard` 的单次操作中。

### SG-02: getCardsByColumn 无缓存

- **文件:** `src/stores/todo.ts` 第 37-81 行
- **影响:** 中等（<100 条卡片无感，数据量增长后可能卡顿）
- **说明:** `getCardsByColumn` 是普通函数而非 `computed`，每次组件重渲染时对每个列重新执行过滤+排序。建议将核心过滤逻辑提升为 computed，或在组件层对每个列的过滤结果使用 `useMemo` 风格的缓存。

### SG-03: reorderColumn O(n²) 复杂度

- **文件:** `src/stores/todo.ts` 第 174-184 行
- **影响:** 低（卡片数量少时无感）
- **说明:** 外层 `forEach` + 内层 `findIndex` 形成 O(n²)。建议改为单次遍历：

```typescript
function reorderColumn(columnId: string) {
  const indices = new Map(cards.value.map((c, i) => [c.id, i]))
  cards.value
    .filter((c) => c.columnId === columnId)
    .sort((a, b) => a.order - b.order)
    .forEach((c, i) => {
      const idx = indices.get(c.id)
      if (idx !== undefined) {
        cards.value[idx] = { ...cards.value[idx], order: i }
      }
    })
}
```

### SG-04: CardModal 模板内联优先级选项数据

- **文件:** `src/components/CardModal.vue` 第 138-143 行
- **影响:** 低（可维护性）
- **说明:** 优先级选项数组定义在 `<template>` 的 `v-for` 中，不利于维护和复用。建议提取为 script 中的常量：

```typescript
const priorityOptions = [
  { value: 'none' as Priority, label: '无', color: '' },
  { value: 'high' as Priority, label: '高', color: 'var(--priority-high)' },
  { value: 'medium' as Priority, label: '中', color: 'var(--priority-medium)' },
  { value: 'low' as Priority, label: '低', color: 'var(--priority-low)' },
]
```

### SG-05: 缺少自动化测试

- **文件:** 全局
- **影响:** 中等（回归风险）
- **说明:** 项目当前 0 个自动化测试。建议至少为核心逻辑添加单元测试：
  - `helpers.ts`: `isOverdue`, `isDueToday`, `formatDate`
  - `storage.ts`: `loadState`, `saveState`（mock localStorage）
  - `todo.ts`: `addCard`, `updateCard`, `deleteCard`, `getCardsByColumn`, `toggleComplete`

---

## 逐文件审查记录

### `src/types/index.ts` (46 行)
- ✅ 类型定义与 design.md 接口定义完全一致
- ✅ `STORAGE_KEY` / `STORAGE_SCHEMA_VERSION` 常量定义清晰
- ✅ `AppState` 接口包含 `version` 字段用于 schema 迁移
- ⚠️ `FilterState.isOverdue` 类型为 `boolean | null`，但实际使用中只用到 `true | null`（`false` 与 `null` 行为相同），可简化为 `boolean | null` 保持一致

### `src/utils/helpers.ts` (34 行)
- ✅ `generateId()` 使用 uuid v4，符合 design.md 选型
- ✅ `isOverdue()` / `isDueToday()` 正确使用 `setHours(0,0,0,0)` 进行日期比较
- ✅ `formatDate()` 正确处理 `null` 输入
- ✅ `nowISO()` 单一职责，返回 ISO 8601 格式

### `src/utils/storage.ts` (124 行)
- ✅ `loadState()` 有完整的 try-catch 保护
- ✅ 损坏数据检测：检查 object 类型 + 数组类型
- ✅ Schema 版本校验：`parsed.version < STORAGE_SCHEMA_VERSION` 时回退默认状态
- ✅ `saveState()` 正确捕获 `QuotaExceededError`
- ✅ `exportJSON()` 使用 Blob + URL.createObjectURL + revokeObjectURL 模式
- ✅ `importJSON()` 使用 FileReader + JSON.parse 校验
- ⚠️ `loadState()` 只验证顶层是数组，不验证数组元素结构（如 card 是否有必要的字段）。如果 localStorage 被手动修改插入无效卡片，会在运行时抛错而非静默回退

### `src/stores/todo.ts` (277 行)
- ✅ Pinia Composition API 风格，state 使用 `ref`
- ✅ `allTags` 为 `computed`，正确使用响应式
- ✅ `addCard` 自动生成 id/timestamp/order
- ✅ `updateCard` 使用 `Partial<Omit<TodoCard, 'id' | 'createdAt'>>` 禁止修改不可变字段
- ✅ `deleteCard` 直接 filter
- ✅ `moveCard` 正确跳过无变更场景
- ✅ `addColumn` 正确校验空标题 + 设置 `isDefault: false`
- ✅ `renameColumn` 正确校验空标题
- ✅ `deleteColumn` 正确校验 `isDefault` 和卡片非空
- ✅ `setFilter` 使用展开合并，支持部分更新
- ✅ `clearFilters` 重置为初始值
- 🔴 **MF-01**: `persist()` 未导出，导致 CardModal 无法触达（见 MUST_FIX）
- ⚠️ **SG-01**: `toggleComplete` 双重 persist
- ⚠️ **SG-02**: `getCardsByColumn` 非 computed
- ⚠️ **SG-03**: `reorderColumn` O(n²)

### `src/components/Board.vue` (57 行)
- ✅ 简单清晰的容器组件，只做事件转发
- 🔴 **MF-03**: `onCardMoved(evt: any)` 使用 `any` 类型
- ⚠️ `import('../types').TodoCard` 内联导入风格与其他文件不一致

### `src/components/Column.vue` (230 行)
- ✅ 列标题支持双击重命名，Enter 确认 / Escape 取消 / blur 确认
- ✅ 重命名输入框自动聚焦（autofocus）
- ✅ 默认列隐藏重命名/删除按钮（`v-if="!column.isDefault"`）
- ✅ 删除前通过 `store.deleteColumn` 校验，失败用 `alert` 提示
- ✅ 拖拽通过 `:data-column-id` / `data-card-id` 传递标识
- 🔴 **MF-03**: `onDragChange(evt: any)` 使用 `any` 类型

### `src/components/Card.vue` (284 行)
- ✅ 优先级颜色条使用绝对定位 4px 宽度，与 design.md 一致
- ✅ 过期红色边框 + 今天到期橙色高亮，正确排除已完成卡片
- ✅ 删除前 `confirm()` 确认
- ✅ 完成复选框调用 `toggleComplete`
- ✅ 操作按钮 hover 显示
- ✅ `priorityLabel` computed 使用 Record 映射
- ⚠️ `priorityClasses` 和 `priorityLabel` 两个 computed 都基于 `props.card.priority`，可合并

### `src/components/CardModal.vue` (417 行)
- ✅ 创建/编辑双模式（`isEdit = computed(() => !!props.card)`）
- ✅ `watch(visible)` 在弹窗打开时初始化表单
- ✅ 标题校验：非空 + ≤200 字符
- ✅ HTML `maxlength="200"` 配合 JS 校验双重保护
- ✅ 优先级 radio 按钮组，`as const` 类型断言正确
- ✅ 标签多选 + 自定义创建
- 🔴 **MF-01**: `createNewTag` 不持久化

### `src/components/SearchBar.vue` (82 行)
- ✅ 使用 `:value` + `@input`（受控模式），数据单向流入 store
- ✅ 清除按钮在搜索词非空时显示
- ✅ 搜索图标 + 清除按钮使用绝对定位
- ⚠️ `onInput` 手动从事件提取 `target.value`，可以直接用 `@input="store.setSearchQuery(($event.target as HTMLInputElement).value)"` 或使用 `v-model` 配合 `computed` setter

### `src/components/FilterPanel.vue` (168 行)
- ✅ 优先级下拉使用 `<select>` 原生控件
- ✅ 标签筛选多选（AND 逻辑）
- ✅ 截止日期/已过期开关按钮
- ✅ 清除按钮仅在筛选激活时显示
- ⚠️ `priorityOptions` 在 script 中定义但 `Priority` 类型与 CardModal 中重复，可抽取到 `types/index.ts` 或 `constants`

### `src/App.vue` (222 行)
- ✅ 根组件布局清晰：header → toolbar → column-controls → board → modal
- ✅ 导出/导入按钮在 header
- ✅ 添加列的内联表单
- ✅ CardModal 通过 `v-if` 控制挂载/卸载
- 🔴 **MF-02**: 导入缺少确认覆盖提示
- ⚠️ `editingCard.value = { ...card }`（第 25 行）浅拷贝，标签数组是引用拷贝。虽然当前逻辑不影响，但如果将来在 `handleSave` 中修改 `editingCard.value` 会影响原卡片

### `src/style.css` (125 行)
- ✅ CSS 变量体系完整：颜色、间距、圆角、阴影、字体均有定义
- ✅ 自定义滚动条样式
- ✅ `@media (max-width: 768px)` 响应式布局
- ✅ 移动端列纵向堆叠、触摸友好尺寸

### `src/main.ts` (9 行)
- ✅ 入口简洁：创建 App → 注册 Pinia → 挂载

---

## 任务完成度详细核对

| 任务 | 状态 | 备注 |
|------|------|------|
| 1.1 ~ 1.4 项目骨架 | ✅ | 完成 |
| 2.1 ~ 2.5 数据层 | ✅ | 完成 |
| 3.1 ~ 3.6 看板布局与 CRUD | ✅ | 完成 |
| 4.1 ~ 4.4 拖拽集成 | ✅ | 完成 |
| 5.1 ~ 5.6 卡片详情与编辑 | ✅ | 完成 |
| 6.1 ~ 6.4 搜索与筛选 | ✅ | 完成 |
| 7.1 ~ 7.3 列管理 | ✅ | 完成 |
| 8.1 ~ 8.6 样式打磨 | ✅ | 完成 |
| 9.1 JSON 导出 | ✅ | 完成 |
| 9.2 JSON 导入 | ⚠️ | 缺少覆盖确认提示 (**MF-02**) |
| 9.3 配额超限 | ✅ | 完成 |
| 9.4 损坏数据回退 | ✅ | 完成 |
| 10.1 ~ 10.4 测试与优化 | ⚠️ | 全部为手动测试，无自动化覆盖 |

---

## 架构一致性验证

- ✅ 三层架构：Presentation (components/) → State (stores/todo.ts) → Persistence (utils/storage.ts)
- ✅ 组件树与 design.md 一致：App → SearchBar + FilterPanel + Board → Column[] → Card[]
- ✅ 数据流单向：用户交互 → Pinia Actions → State 更新 → localStorage 持久化
- ✅ `getCardsByColumn` 实现综合过滤（keyword + priority + tagIds + hasDueDate + isOverdue）
- ✅ 默认列不可删除（`isDefault` 保护）
- ✅ Schema 版本管理（`STORAGE_SCHEMA_VERSION = 1`）
- ✅ 类型定义与 design.md 接口完全吻合

---

## 总体评价

代码整体质量**良好**，架构设计严格遵循 design.md 的三层架构规划，组件职责清晰，TypeScript 类型体系完整（除 4 处 `any` 外）。CSS 变量系统和响应式布局设计专业。

**3 个 MUST_FIX 项必须修复后方可进入 TEST 阶段：**

1. **MF-01（严重）**: 自定义标签不持久化 — 用户创建的标签刷新后丢失
2. **MF-02（高）**: JSON 导入缺少覆盖确认 — tasks.md 明确要求的交互缺失
3. **MF-03（高）**: 4 处 `any` 类型 — 绕过了 TypeScript 类型安全保障

**5 个 SUGGEST 项** 不影响核心功能正确性，建议在后续迭代中逐步改进，特别是补充自动化测试覆盖（目前 0 测试）。
