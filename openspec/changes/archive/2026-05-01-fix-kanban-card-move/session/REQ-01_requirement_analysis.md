# 需求分析: 修复工作项无法在不同列移动的问题

## 问题描述

用户在使用看板时，无法通过拖拽将卡片（工作项）从一个列移动到另一个列。拖拽操作视觉上似乎有反馈，但实际数据并未更新，卡片会回到原列。

## 影响范围

- 看板的核心交互——跨列拖拽完全失效
- 用户只能通过间接方式（如编辑卡片修改状态）来变更卡片所属列
- 影响所有列之间的拖拽操作

## 根本原因

代码审查发现两个问题：

### 1. computed setter 为空函数

`Column.vue` 中 `cards` computed 属性的 setter 被设为空函数：

```typescript
const cards = computed({
  get: () => store.getCardsByColumn(props.column.id),
  set: () => {}, // 拒绝写入
});
```

`vuedraggable` 的 `:list` 绑定到 `cards`，拖拽后试图通过 setter 更新数据，但 setter 不做任何事，数据永远写不进 Pinia store。

### 2. onDragChange 不处理跨列场景

`onDragChange()` 只检查同列内卡片排序是否变化，当跨列拖拽发生时，`displayCards.length !== ordered.length`，条件跳过，`moveCard` 从未被调用。

## 验收标准

1. 用户可将卡片从任一列拖拽到另一列
2. 拖拽后卡片数据正确更新（columnId 和 order）
3. 源列和目标列的卡片排序正确
4. 页面刷新后数据保持正确
