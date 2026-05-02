# DES-02: 方案设计 — add-list-view

## 架构决策

### 视图切换机制

```
App.vue
  viewMode = store.viewMode  (reactive)
  
  Template:
    <SearchBar />         ← 共享
    <FilterPanel />       ← 共享
    <Board v-if="viewMode === 'board'" />
    <ListView v-else />
    <CardModal />         ← 共享
```

- viewMode 存在 Pinia store 中，变更时自动持久化到 localStorage
- Board 和 ListView 互斥渲染（v-if/v-else），不浪费性能

### 数据流

```
store.viewMode  ───持久化──→  localStorage
     │
     ├── 'board'  →  Board.vue   →  Column.vue[]  →  Card.vue[]
     │
     └── 'list'   →  ListView.vue
                        │
                        ├── computed: groupedCards = columns.map(col => ({
                        │       column, cards: store.getCardsByColumn(col.id)
                        │     })).filter(g => g.cards.length > 0)
                        │
                        └── 复用 Card.vue 样式（在列表项中内联渲染）
```

### 组件树对比

**看板**: Board → Column (vuedraggable) → Card  
**列表**: ListView → 分组标题 → 内联卡片（无拖拽包裹）

## 修改清单

### 1. `src/types/index.ts`

```ts
// AppState 新增字段
export interface AppState {
  columns: Column[]
  cards: TodoCard[]
  tags: Tag[]
  viewMode: 'board' | 'list'  // 新增
}
```

### 2. `src/stores/todo.ts`

```ts
const viewMode = ref<'board' | 'list'>('board')

// 从 localStorage 恢复
function loadFromStorage(): void {
  const saved = loadState()
  if (saved) {
    // ...
    viewMode.value = saved.viewMode || 'board'
  }
}

// 切换视图
function setViewMode(mode: 'board' | 'list'): void {
  viewMode.value = mode
  persist()
}

// 持久化时包含 viewMode
function persist(): void {
  saveState({
    columns: columns.value,
    cards: cards.value,
    tags: tags.value,
    viewMode: viewMode.value,  // 新增
  })
}
```

### 3. `src/App.vue`

工具栏区域新增视图切换按钮：

```html
<div class="view-toggle">
  <button :class="{ active: store.viewMode === 'board' }" 
          @click="store.setViewMode('board')">看板</button>
  <button :class="{ active: store.viewMode === 'list' }" 
          @click="store.setViewMode('list')">列表</button>
</div>

<!-- 条件渲染 -->
<Board v-if="store.viewMode === 'board'" />
<ListView v-else />
```

### 4. `src/components/ListView.vue` (新增)

核心结构：

```
<template>
  <div class="list-view">
    <div v-for="group in groupedColumns" :key="group.column.id" class="list-group">
      <!-- 分组标题 -->
      <div class="list-group-header" @click="toggleCollapse(group.column.id)">
        <span class="collapse-icon">{{ collapsed ? '▶' : '▼' }}</span>
        <h3>{{ group.column.title }}</h3>
        <span class="list-group-count">{{ group.cards.length }}</span>
      </div>
      
      <!-- 卡片列表 -->
      <div v-if="!collapsed" class="list-group-cards">
        <div v-for="card in group.cards" :key="card.id" class="list-card">
          <!-- 内联渲染卡片内容（同 Card.vue 结构，无拖拽） -->
          <label class="card-checkbox">...</label>
          <div class="card-body">...</div>
          <div class="card-actions">...</div>
        </div>
      </div>
    </div>
    
    <!-- 空状态 -->
    <div v-if="noResults" class="no-results">未找到匹配的卡片</div>
  </div>
</template>
```

**关键细节**：
- 卡片复用 Card.vue 的核心 HTML 结构和样式，但不包裹 vuedraggable
- 编辑、删除、完成操作通过 emit 交给 App.vue → store
- 折叠状态用本地 `ref<Set>` 管理，不持久化

## 风险与约束

| 风险 | 缓解 |
|------|------|
| Card.vue 的样式和逻辑需要复用 | 在 ListView 中内联渲染相同结构，不复用 Card.vue 组件（避免拖拽绑定） |
| localStorage 数据结构变化 | viewMode 新增字段，旧数据无该字段时默认 'board'，向后兼容 |
| 两视图切换时搜索/筛选状态保持 | viewMode 与 searchQuery/filters 在同一 store 中，天然共享 |
