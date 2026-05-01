## Why

看板跨列拖拽功能完全失效。`Column.vue` 中 `cards` computed setter 为空函数，且 `onDragChange` 不处理跨列场景，导致拖拽后卡片回到原列。该功能是看板的核心交互，需要立即修复。

## What Changes

- 修复 `Column.vue` 中 `cards` computed 的 setter 为空函数的问题
- 重写 `onDragChange` 方法，使其正确响应 `vuedraggable` 的 `@change` 事件处理跨列拖拽
- 利用 `store.moveCard()` 已有正确逻辑完成数据更新

## Capabilities

### New Capabilities

无新增能力。

### Modified Capabilities

本次为纯 bug 修复，原有需求不变，不涉及新增能力层面的 spec 变更。修复后的行为通过 delta spec（`specs/kanban-board/spec.md`）记录验收场景，共 7 个 Given-When-Then 场景覆盖正常/异常/边界情况。

## Impact

- 仅修改 `Column.vue` 一个文件
- 不影响 store 层、Card 组件、模板结构
- 无新增依赖
