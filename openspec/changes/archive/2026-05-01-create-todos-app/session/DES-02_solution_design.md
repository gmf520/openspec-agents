# 方案设计: create-todos-app

## 1. 设计目标

构建一个基于 Vue 3 + TypeScript 的单页看板式 Todo 管理应用，支持卡片拖拽、优先级/标签/截止日期管理、搜索筛选，数据持久化于 localStorage。

## 2. 方案对比

| 维度       | 方案A: Vue 3 SPA (推荐)         | 方案B: Nuxt 3 SSR      | 方案C: 纯 HTML/JS    |
| ---------- | ------------------------------- | ---------------------- | -------------------- |
| 实现复杂度 | 低                              | 中                     | 低（但功能多时失控） |
| 性能影响   | SPA 首次加载后流畅              | SSR 首屏快但服务器依赖 | 可接受               |
| 可维护性   | 高（组件化+TS类型安全）         | 高                     | 低（无模块化）       |
| 生态支持   | 丰富（Pinia/Vuedraggable/Vite） | 丰富                   | 贫乏                 |
| 部署       | 静态文件，零配置                | 需 Node 服务器         | 静态文件             |
| 适用场景   | 纯前端应用，无 SEO 需求         | 需 SEO 的应用          | 极简原型             |

**结论:** 采用方案A。Todos 应用无 SEO 需求，纯前端 SPA + localStorage 是最佳匹配。

## 3. 推荐方案

### 3.1 架构概览

```
┌─────────────────────────────────────────────────────┐
│                    Vue 3 App                         │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ SearchBar│  │FilterPanel│  │  Board Header     │  │
│  └──────────┘  └──────────┘  └───────────────────┘  │
│                                                      │
│  ┌─────────────────────────────────────────────────┐ │
│  │                  Board (Kanban)                  │ │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │ │
│  │  │ Column   │  │ Column   │  │ Column       │  │ │
│  │  │ 待办     │  │ 进行中   │  │ 已完成       │  │ │
│  │  │ ┌──────┐ │  │ ┌──────┐ │  │ ┌──────────┐ │  │ │
│  │  │ │ Card │ │  │ │ Card │ │  │ │ Card     │ │  │ │
│  │  │ │ Card │ │  │ │ Card │ │  │ │ Card     │ │  │ │
│  │  │ └──────┘ │  │ └──────┘ │  │ └──────────┘ │  │ │
│  │  │ +Add     │  │ +Add     │  │ +Add         │  │ │
│  │  └──────────┘  └──────────┘  └──────────────┘  │ │
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  ┌─────────────────────────────────────────────────┐ │
│  │              Pinia Store (state)                 │ │
│  │   columns[], cards[], tags[], filters{}         │ │
│  └──────────────────────┬──────────────────────────┘ │
│                         │                             │
│  ┌──────────────────────▼──────────────────────────┐ │
│  │         localStorage (persistence)               │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 3.2 模块划分

| 模块               | 职责                          | 依赖          | 关键接口                       |
| ------------------ | ----------------------------- | ------------- | ------------------------------ |
| `App.vue`          | 根组件，布局容器              | —             | —                              |
| `Board.vue`        | 看板容器，管理列间拖拽        | Column, Pinia | `props: { columns: Column[] }` |
| `Column.vue`       | 单列渲染，列内拖拽            | Card, Pinia   | `props: { column: Column }`    |
| `Card.vue`         | 单卡片渲染                    | Pinia         | `props: { card: TodoCard }`    |
| `SearchBar.vue`    | 搜索输入框                    | Pinia         | 更新 `store.searchQuery`       |
| `FilterPanel.vue`  | 多条件筛选面板                | Pinia         | 更新 `store.filters`           |
| `CardModal.vue`    | 创建/编辑卡片弹窗             | Pinia         | `props: { card?: TodoCard }`   |
| `stores/todo.ts`   | Pinia 状态管理 + localStorage | —             | CRUD + 搜索筛选 + 持久化       |
| `types/index.ts`   | TypeScript 类型定义           | —             | TodoCard, Column, Filter, Tag  |
| `utils/storage.ts` | localStorage 读写封装         | —             | `loadState()`, `saveState()`   |
| `utils/helpers.ts` | 辅助函数（日期检查等）        | —             | `isOverdue()`, `isDueToday()`  |

### 3.3 数据流

```
用户操作 → 组件事件 → Pinia Action → 更新 State → localStorage 持久化
                                                ↓
                                          组件响应式重渲染
                                                ↓
                                          UI 更新完成
```

**搜索/筛选流:**

```
用户输入搜索词/筛选条件 → Pinia store.getters.filteredCards → 组件仅渲染匹配卡片
```

### 3.4 接口定义

```typescript
// types/index.ts

interface TodoCard {
  id: string; // UUID
  title: string; // 标题（必填）
  description: string; // 描述（可选）
  columnId: string; // 所属列 ID
  priority: Priority; // 优先级
  tags: Tag[]; // 标签列表
  dueDate: string | null; // 截止日期 ISO string
  completed: boolean; // 是否完成
  createdAt: string; // 创建时间 ISO string
  updatedAt: string; // 更新时间 ISO string
  order: number; // 列内排序序号
}

type Priority = "high" | "medium" | "low" | "none";

interface Tag {
  id: string;
  name: string;
  color: string; // hex color
}

interface Column {
  id: string;
  title: string;
  isDefault: boolean; // 默认列不可删除
  order: number;
}

interface FilterState {
  priority: Priority | "all";
  tagIds: string[];
  hasDueDate: boolean | null; // null=不限, true=有, false=无
  isOverdue: boolean | null;
}
```

**Pinia Store 核心 Actions:**

```typescript
// stores/todo.ts

interface TodoStore {
  // State
  columns: Column[];
  cards: TodoCard[];
  tags: Tag[];
  searchQuery: string;
  filters: FilterState;

  // Getters
  filteredCards: (columnId: string) => TodoCard[];
  allTags: Tag[];
  overdueCards: TodoCard[];

  // Actions
  addCard(card: Omit<TodoCard, "id" | "createdAt" | "updatedAt" | "order">): void;
  updateCard(id: string, updates: Partial<TodoCard>): void;
  deleteCard(id: string): void;
  moveCard(cardId: string, targetColumnId: string, newOrder: number): void;
  addColumn(title: string): void;
  renameColumn(id: string, title: string): void;
  deleteColumn(id: string): void;
  setSearchQuery(query: string): void;
  setFilter(filter: Partial<FilterState>): void;
  addTag(name: string, color: string): void;
  loadFromStorage(): void;
  saveToStorage(): void;
}
```

### 3.5 关键决策记录

| 决策                      | 理由                                | 替代方案                               |
| ------------------------- | ----------------------------------- | -------------------------------------- |
| Pinia 而非 Vuex           | Vue 3 官方推荐，TypeScript 支持更好 | Vuex 4（更重，API 较旧）               |
| Vuedraggable 而非原生拖拽 | SortableJS 封装成熟，减少兼容性坑   | 原生 HTML5 Drag API（事件处理复杂）    |
| localStorage 直接同步     | 简单可靠，每次操作立即写入          | IndexedDB（过度设计，5MB 够用）        |
| 默认3列不可删             | 保证最小可用结构，避免用户误删      | 完全自由（可能导致空看板）             |
| UUID 作为卡片 ID          | 唯一性好，无碰撞，不依赖自增        | 自增 ID（localStorage 场景下可能重复） |

## 4. 实施计划概要

| 阶段                | 内容                                            | 预估工作量 |
| ------------------- | ----------------------------------------------- | ---------- |
| Phase 1: 项目骨架   | Vite + Vue 3 + TS 初始化，目录结构搭建          | 30min      |
| Phase 2: 数据层     | TypeScript 类型、Pinia Store、localStorage 封装 | 1h         |
| Phase 3: 看板布局   | Board + Column + Card 组件，基础 CRUD           | 1.5h       |
| Phase 4: 拖拽       | Vuedraggable 集成，列间/列内拖拽                | 1h         |
| Phase 5: 卡片详情   | 编辑弹窗、优先级、标签、截止日期 UI             | 1.5h       |
| Phase 6: 搜索筛选   | SearchBar + FilterPanel，Store Getter 过滤      | 1h         |
| Phase 7: 列管理     | 添加/重命名/删除自定义列                        | 0.5h       |
| Phase 8: 样式打磨   | CSS 美化、响应式                                | 1h         |
| Phase 9: 测试与优化 | 功能测试、边界情况处理                          | 1h         |

**总计预估：** 约 8-9 小时

## 5. 回滚方案

- 所有代码在 `src/` 目录下，删除即回滚
- localStorage 数据独立于代码，删除代码不影响数据
- 提供 JSON 导出功能，用户可随时备份数据
