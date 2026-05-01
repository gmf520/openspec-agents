## 1. 理解和定位

- [x] 1.1 阅读 `Column.vue` 源码，确认 `cards` computed 和 `onDragChange` 的当前实现
- [x] 1.2 阅读 `store.moveCard()` 源码，确认其跨列处理逻辑正确

## 2. 实现修复

- [x] 2.1 将 `cards` computed 替换为 `ref + watch` 响应式引用，移除 `:list` 绑定
- [x] 2.2 定义或导入 `AddedData`/`MovedData`/`RemovedData` TypeScript 接口（在 `Column.vue` 或独立 types 文件中），确保 `onDragChange` 参数有正确类型标注
- [x] 2.3 重写 `onDragChange`，利用 `vuedraggable` 的 `@change` 事件处理 `added` 和 `moved` 场景
- [x] 2.4 验证模板绑定正确，移除对废弃 `cards` computed 的引用

## 3. 验证（映射 specs/kanban-board/spec.md 场景）

### Spec 场景 1: 拖拽到有数据的列

- [x] 3.1 将"待办"列中的卡片拖拽到"进行中"列（目标列已有卡片）→ 验证卡片从源列消失、出现在目标列正确位置、columnId 更新、其他卡片顺序不变

### Spec 场景 2: 拖拽到空列

- [x] 3.2 将卡片拖拽到一个空列 → 验证卡片出现在空列中、作为该列唯一卡片、columnId 更新

### Spec 场景 3: 同列重排序

- [x] 3.3 在同一列内将第 3 张卡片拖到第 1 张上方 → 验证被拖拽卡片排到第 1 位、其他卡片顺序相应上移

### Spec 场景 4: 拖回原列

- [x] 3.4 将卡片拖到目标列后再拖回原列 → 验证卡片回到原列的正确位置、数据正确

### Spec 场景 5: 拖拽到无效目标

- [x] 3.5 将卡片拖放到非列区域（如页面空白处）→ 验证卡片回到原始位置、不发生任何变更

### Spec 场景 6: 源列顺序保留

- [x] 3.6 从"待办"列拖走一张卡片 → 验证原列剩余卡片顺序正确、没有重复或丢失

### Spec 场景 7: 刷新后数据保持

- [x] 3.7 跨列拖拽卡片后刷新页面 → 验证卡片保持在拖拽后位置、columnId 和 order 正确持久化
