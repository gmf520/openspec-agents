## Context

从零构建一个基于 Vue 3 + TypeScript + Vite 的看板式 Todo 管理 SPA。无现有代码库依赖，纯前端实现，数据通过 localStorage 持久化。项目采用组件化架构，分阶段增量交付。

**约束条件:**

- 技术栈: Vue 3 Composition API + TypeScript + Vite
- 存储: localStorage（上限约 5MB）
- 浏览器: Chrome/Firefox/Edge/Safari 最近 2 个主版本
- 性能: 初始加载 < 2s，< 100 条卡片无明显卡顿

## Goals / Non-Goals

**Goals:**

- 提供清晰的分层架构（组件层→状态层→持久层）
- 确定核心依赖选型及理由
- 定义完整的 TypeScript 类型与接口
- 规划数据流和组件通信模式

**Non-Goals:**

- 后端 API 设计
- 用户认证与权限模型
- SSR/SSG 方案
- CI/CD 流水线设计

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Presentation Layer                  │
│  ┌─────────┐ ┌──────────┐ ┌───────────┐ ┌──────────┐  │
│  │SearchBar │ │FilterPanel│ │ Board     │ │CardModal │  │
│  └─────────┘ └──────────┘ └─────┬─────┘ └────┬─────┘  │
│                                 │              │        │
│                          ┌──────▼──────┐       │        │
│                          │  Column[]   │       │        │
│                          │  ┌───────┐  │       │        │
│                          │  │ Card[]│  │       │        │
│                          │  └───────┘  │       │        │
│                          └──────┬──────┘       │        │
├─────────────────────────────────┼──────────────┼────────┤
│                      State Layer │              │        │
│                          ┌──────▼──────────────▼──┐    │
│                          │     Pinia TodoStore      │    │
│                          │  columns, cards, tags,   │    │
│                          │  searchQuery, filters    │    │
│                          │  getters + actions       │    │
│                          └──────────┬───────────────┘    │
├─────────────────────────────────┼───────────────────────-┤
│                     Persistence Layer                    │
│                          ┌──────▼──────────────────┐    │
│                          │       localStorage       │    │
│                          └─────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

**分层职责:**

- **Presentation**: Vue 单文件组件，仅处理 UI 交互，通过 Pinia actions/getters 读写状态
- **State**: Pinia Store 持有全部应用状态，包含业务逻辑（CRUD、过滤、排序），自动触发持久化
- **Persistence**: utils/storage.ts 封装 localStorage 读写，提供 loadState/saveState 接口

## Component Design

### 组件树

```
App.vue
├── SearchBar.vue
├── FilterPanel.vue
├── Board.vue (vuedraggable)
│   └── Column.vue[] (vuedraggable)
│       ├── 列标题栏（内联，含重命名/删除按钮）
│       └── Card.vue[]
│           ├── 优先级标识 (颜色条)
│           ├── 标签徽章 (Tag)
│           ├── 截止日期 (过期高亮)
│           └── 操作按钮 (编辑/删除)
└── CardModal.vue (创建/编辑弹窗)
    ├── 标题输入
    ├── 描述输入
    ├── 优先级选择
    ├── 标签选择器
    └── 截止日期选择器
```

### 核心组件职责

| 组件          | Props                                 | Events                                 | 状态来源                                  |
| ------------- | ------------------------------------- | -------------------------------------- | ----------------------------------------- |
| `Board`       | —                                     | —                                      | `store.columns`, `store.getCardsByColumn` |
| `Column`      | `column: Column`, `cards: TodoCard[]` | `@rename`, `@delete`                   | 通过 props 接收                           |
| `Card`        | `card: TodoCard`                      | `@edit`, `@delete`, `@toggle-complete` | 通过 props 接收                           |
| `SearchBar`   | —                                     | —                                      | 写入 `store.searchQuery`                  |
| `FilterPanel` | —                                     | —                                      | 写入 `store.filters`                      |
| `CardModal`   | `visible`, `card?`                    | `@close`, `@save`                      | 表单本地状态                              |

### 接口定义

```typescript
// types/index.ts

type Priority = "high" | "medium" | "low" | "none";

interface Tag {
  id: string;
  name: string;
  color: string;
}

interface TodoCard {
  id: string;
  title: string;
  description: string;
  columnId: string;
  priority: Priority;
  tags: Tag[];
  dueDate: string | null; // ISO 8601
  completed: boolean;
  createdAt: string; // ISO 8601
  updatedAt: string; // ISO 8601
  order: number;
}

interface Column {
  id: string;
  title: string;
  isDefault: boolean;
  order: number;
}

interface FilterState {
  priority: Priority | "all";
  tagIds: string[];
  hasDueDate: boolean | null;
  isOverdue: boolean | null;
}

// Pinia Store 核心接口
interface TodoStore {
  // State
  columns: Column[];
  cards: TodoCard[];
  tags: Tag[];
  searchQuery: string;
  filters: FilterState;

  // Getters
  getCardsByColumn: (columnId: string) => TodoCard[];
  allTags: Tag[];
}

interface CreateCardInput {
  title: string;
  description?: string;
  columnId: string;
  priority?: Priority;
  tags?: Tag[];
  dueDate?: string | null;
}
```

### 数据流

```
用户交互 (点击/输入/拖拽)
        │
        ▼
  组件事件处理
        │
   ┌────┴────┐
   │ Pinia   │── getters ──→ 组件读取数据 ──→ UI 重渲染
   │ Actions │
   └────┬────┘
        │ 状态变更
        ▼
   localStorage.saveState()
        │
        ▼
   数据持久化完成
```

**搜索筛选流:**

```
用户输入搜索词/筛选条件
        │
        ▼
  store.searchQuery / store.filters 更新
        │
        ▼
  store.getCardsByColumn(columnId) 计算
        │  ┌─ keyword 匹配 (title + description + tag name)
        │  ├─ priority 过滤
        │  ├─ tagIds 过滤
        │  ├─ hasDueDate 过滤
        │  └─ isOverdue 过滤
        ▼
  过滤后的卡片列表 → 组件渲染
```

## Decisions

| 决策                                       | 理由                                                    | 替代方案                                  |
| ------------------------------------------ | ------------------------------------------------------- | ----------------------------------------- |
| **Pinia** (而非 Vuex)                      | Vue 3 官方推荐，完整 TypeScript 支持，模块化设计更灵活  | Vuex 4（API 繁重，类型推断弱）            |
| **vuedraggable** (而非原生拖拽)            | SortableJS 成熟封装，处理触摸/排序/动画，减少兼容性工作 | 原生 HTML5 Drag API（需大量事件处理代码） |
| **localStorage 直接同步** (而非 IndexedDB) | API 简单，同步读写，容量足够（预估数据量 < 1MB）        | IndexedDB（过度设计，异步增加复杂度）     |
| **UUID** (而非自增ID)                      | 唯一性好，无碰撞，支持 localStorage 多次读写场景        | 自增 ID（可能因数据重置导致重复）         |
| **默认列不可删**                           | 保证最小可用结构，避免空看板                            | 完全自由（用户体验风险高）                |
| **vuedraggable 整包引入** (而非树摇)       | 包体积可控（~30KB gzip），使用其全部功能                | 按需引入（无 Tree Shaking 支持）          |

## Risks / Trade-offs

| 风险                           | 影响               | 缓解措施                                              |
| ------------------------------ | ------------------ | ----------------------------------------------------- |
| localStorage 数据意外丢失      | 用户数据全丢       | 提供 JSON 导出/导入备份；每次保存前校验数据结构完整性 |
| 大数量卡片（>500）列表渲染卡顿 | UI 卡顿            | MVP 阶段做虚拟滚动预留接口，实际触发阈值监控          |
| 拖拽在各浏览器行为不一致       | 部分浏览器拖拽异常 | vuedraggable 已处理多浏览器兼容；E2E 覆盖主流浏览器   |
| 移动端拖拽体验差               | 移动端用户抱怨     | 移动端优先支持点击移动（上下箭头），长按拖拽为备选    |
| localStorage 配额超限（>5MB）  | 无法保存新数据     | 保存失败时提示用户清理或导出数据；监测写入异常        |
