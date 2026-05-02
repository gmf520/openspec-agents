## Why

当前 Todos 应用仅支持看板（Board）视图，卡片按列分组横向展示。当任务数量较多时，横向布局的浏览效率较低，用户需要一种纵向列表视图来更高效地浏览和定位卡片。

## What Changes

- 工具栏新增视图切换按钮（看板 / 列表），支持两种视图互相切换
- 新增 ListView 组件，以纵向列表方式按列（状态）分组展示卡片
- 列表视图复用看板卡片的全部信息展示（标题、描述、标签、优先级、截止日期、完成状态）
- 列表卡片支持 checkbox 勾选完成/取消完成
- 列表卡片仅查看模式，点击编辑/删除弹出 CardModal
- 两个视图共享搜索和筛选状态
- 视图偏好存入 localStorage，刷新后自动恢复
- 列表视图不包含拖拽功能，无新增依赖

## Capabilities

### New Capabilities
- `list-view`: 纵向列表视图，按列分组展示任务卡片，支持折叠分组、卡片级操作（完成/编辑/删除），与看板视图互斥切换

### Modified Capabilities
<!-- No existing capabilities are being modified. This change adds a new view option without altering existing spec-level behavior. -->

## Impact

- `src/types/index.ts`: AppState 接口新增 `viewMode` 字段
- `src/stores/todo.ts`: 新增 viewMode 状态、setViewMode 方法，持久化包含 viewMode
- `src/App.vue`: 工具栏新增视图切换按钮，条件渲染 Board / ListView
- `src/components/ListView.vue`: 新增组件（核心变更）
- 无新增第三方依赖
- localStorage 数据结构向后兼容（旧数据默认 board 视图）
