## Intent

创建一个基于看板的 Todo 管理单页应用（SPA），帮助用户高效管理个人任务。支持可视化拖拽排序、多维度标记（优先级/标签/截止日期）和实时搜索筛选，数据持久化于浏览器 localStorage，无需后端。

## Scope

**In Scope:**
- Todo 卡片的创建、编辑、删除和拖拽移动
- 看板式多列布局（默认三列：待办/进行中/已完成），支持自定义列管理
- 优先级标记（高/中/低/无），卡片颜色可视化区分
- 标签/分类管理，支持多选和自定义颜色
- 截止日期设置，过期和即将到期高亮提醒
- 关键词搜索（标题+描述+标签名）和组合条件筛选（优先级/标签/截止日期/过期）
- localStorage 自动持久化，页面刷新数据不丢失
- 响应式布局，适配桌面和移动端
- JSON 导出/导入作为数据备份

**Out of Scope:**
- 用户认证与多用户支持
- 后端 API 与数据库存储
- 团队协作与实时同步
- 文件附件上传
- 推送通知与提醒
- 暗色模式（留作后续迭代）
- 国际化/多语言

## Capabilities

### New Capabilities

- `todo-crud`: Todo 卡片全生命周期管理——创建（含标题/描述/优先级/标签/截止日期）、编辑、删除、标记完成/取消完成
- `kanban-board`: 看板布局与拖拽管理——多列渲染、列间/列内拖拽排序、自定义列增删改名、默认列保护
- `search-filter`: 搜索与筛选——关键词实时搜索、多条件组合筛选（优先级/标签/截止日期/过期状态）
- `data-persistence`: 数据持久化——localStorage 自动读写、状态初始化加载、JSON 导出/导入备份

### Modified Capabilities

<!-- 无现有 specs，无需修改 -->

## Approach

采用 Vue 3 + TypeScript + Vite 构建纯前端 SPA。使用 Pinia 进行状态管理，vuedraggable（基于 SortableJS）实现拖拽，localStorage 直接同步持久化。遵循组件化开发，按 Phase 分阶段交付（项目骨架→数据层→看板布局→拖拽→卡片详情→搜索筛选→列管理→样式打磨→测试优化）。

## Impact

- **新增代码**: `src/` 目录下约 15-20 个文件（Vue 组件、Pinia Store、TypeScript 类型、工具函数、Vite 配置）
- **新增依赖**: vue 3, pinia, vuedraggable, uuid, vite, typescript
- **无破坏性变更**: 从零构建，不修改现有代码
- **部署方式**: 纯静态文件，支持任意 Web 服务器或 GitHub Pages
