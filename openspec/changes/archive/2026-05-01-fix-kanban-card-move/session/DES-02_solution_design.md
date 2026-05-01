# 方案设计: 修复跨列拖拽

## 方案选择

采用最小修改方案，仅修复 `Column.vue` 中的 `onDragChange` 和 `cards` computed，不修改 store 层逻辑。

## 具体修改

### 修改 1: 替换 cards computed 为响应式引用

将 `cards` computed 替换为调用 `store.getCardsByColumn()` 的方法，不再使用 `:list` 绑定到 computed。改为监听 `vuedraggable` 的 `@change` 事件处理数据变更。

### 修改 2: 重写 onDragChange

利用 `vuedraggable` `@change` 事件提供的 `added`、`removed`、`moved` 信息精确处理：

- `added`（跨列移入）：调用 `store.moveCard(cardId, thisColumnId, newIndex)`
- `moved`（同列重排序）：调用 `store.moveCard(cardId, thisColumnId, newIndex)`

直接根据 event 信息调用 `store.moveCard`，不再通过数组长度比对来推测变化。

### 不修改的部分

- `store.moveCard()` 已有正确的跨列处理逻辑（更新 source 列和 target 列的 order）
- 模板结构不变
- Card 组件不变

## 风险

- 低。修改范围局限在单个组件的两个函数
- `vuedraggable` 的 `@change` 事件参数格式需确认（added/moved 的 payload 结构）
