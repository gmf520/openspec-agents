## 1. 项目骨架

- [x] 1.1 使用 Vite 初始化 Vue 3 + TypeScript 项目，配置 tsconfig.json 和 vite.config.ts
- [x] 1.2 安装核心依赖：pinia, vuedraggable, uuid
- [x] 1.3 创建目录结构：`src/components/`, `src/stores/`, `src/types/`, `src/utils/`, `src/assets/`
- [x] 1.4 创建 App.vue 根组件，设置基础布局容器

## 2. 数据层

- [x] 2.1 定义 TypeScript 类型：`TodoCard`, `Column`, `Tag`, `Priority`, `FilterState`（`src/types/index.ts`）
- [x] 2.2 实现 localStorage 封装：`loadState()`, `saveState()`（`src/utils/storage.ts`），含数据校验和异常处理
- [x] 2.3 实现辅助函数：`isOverdue()`, `isDueToday()`, `generateId()`（`src/utils/helpers.ts`）
- [x] 2.4 创建 Pinia TodoStore：定义 state、getters（`getCardsByColumn`, `allTags`）、actions 骨架（`src/stores/todo.ts`）
- [x] 2.5 实现初始化逻辑：`loadFromStorage()` 从 localStorage 恢复状态，无数据时使用默认三列和预设标签

## 3. 看板布局与基础 CRUD

- [x] 3.1 创建 Board.vue 组件，遍历 columns 渲染多列布局
- [x] 3.2 创建 Column.vue 组件，渲染列标题和卡片列表
- [x] 3.3 创建 Card.vue 组件，显示标题、优先级颜色条、标签徽章、截止日期
- [x] 3.4 实现 `addCard` action：创建新卡片到指定列，自动生成 ID、时间戳和排序序号
- [x] 3.5 实现 Card 的完成/取消完成切换（`updateCard`），将卡片移入/移出"已完成"列
- [x] 3.6 实现 Card 的删除功能：带确认对话框，调用 `deleteCard` action

## 4. 拖拽集成

- [x] 4.1 在 Board.vue 中集成 Vuedraggable，实现列间卡片拖拽移动
- [x] 4.2 在 Column.vue 中集成 Vuedraggable，实现列内卡片排序拖拽
- [x] 4.3 实现 `moveCard` action：更新 columnId 和 order，重新计算同列卡片排序
- [x] 4.4 添加拖拽动画和占位符样式

## 5. 卡片详情与编辑

- [x] 5.1 创建 CardModal.vue 组件：编辑弹窗（标题、描述、优先级、标签、截止日期），支持创建和编辑两种模式
- [x] 5.2 实现优先级选择器（高/中/低/无），卡片上显示对应颜色条
- [x] 5.3 实现标签选择器：显示预设标签（工作/个人/学习/紧急），支持多选和自定义标签创建
- [x] 5.4 实现截止日期选择器，卡片上显示日期及过期/今天到期高亮
- [x] 5.5 实现 `updateCard` action 支持部分字段更新，编辑后更新 `updatedAt` 时间戳
- [x] 5.6 添加表单验证：标题非空且不超过 200 字符

## 6. 搜索与筛选

- [x] 6.1 创建 SearchBar.vue 组件：搜索输入框，emit 输入事件更新 store.searchQuery
- [x] 6.2 创建 FilterPanel.vue 组件：筛选面板（优先级下拉、标签多选、截止日期开关、过期开关）
- [x] 6.3 实现 `getCardsByColumn` getter：综合搜索词 + 筛选条件返回过滤后的卡片列表
- [x] 6.4 实现 `setSearchQuery` 和 `setFilter` actions，支持清除所有筛选

## 7. 列管理

- [x] 7.1 实现 `addColumn` action：点击"添加列"按钮，弹出输入框，创建自定义列
- [x] 7.2 实现 `renameColumn` action：双击列标题可编辑，非空验证
- [x] 7.3 实现 `deleteColumn` action：仅允许删除非默认列，该列有卡片时提示先移动或删除卡片

## 8. 样式打磨

- [x] 8.1 设计 CSS 变量系统：颜色主题、间距、圆角、阴影
- [x] 8.2 看板区域样式：横向滚动、列等高、拖拽悬停效果
- [x] 8.3 卡片样式：圆角卡片、悬停阴影、优先级颜色条、过期红色边框
- [x] 8.4 搜索筛选栏样式：顶部固定、输入框图标、筛选面板折叠/展开
- [x] 8.5 弹窗样式：居中模态框、遮罩层、表单布局
- [x] 8.6 响应式布局：移动端列纵向堆叠，触摸友好的卡片尺寸

## 9. 数据备份与边界处理

- [x] 9.1 实现 JSON 导出功能：序列化 state 为 JSON，触发浏览器下载
- [x] 9.2 实现 JSON 导入功能：文件读取、格式验证、确认覆盖提示
- [x] 9.3 添加 localStorage 配额超限处理：捕获异常，提示用户清理或导出
- [x] 9.4 添加损坏数据回退：loadFromStorage 中 try-catch，格式不符时静默回退默认状态

## 10. 测试与优化

- [x] 10.1 手动功能测试：按 spec 场景逐项验证 CRUD、拖拽、搜索筛选、列管理
- [x] 10.2 边界测试：空标题提交、超长标题、空看板、大量数据（100+ 卡片）性能
- [x] 10.3 数据持久化测试：刷新页面验证数据恢复、清理 localStorage 后默认状态
- [x] 10.4 多浏览器快速验证：Chrome、Firefox、Edge 基础功能检查
