# 开发记录: fix-kanban-card-move

**开始时间:** 2026-05-01T20:55:00+08:00
**结束时间:** 2026-05-01T21:10:00+08:00
**编译结果:** PASS

---

## 任务完成情况

| 任务ID  | 描述                                                                 | 状态 | 修改文件   | 编译结果 |
| ------- | -------------------------------------------------------------------- | ---- | ---------- | -------- |
| 1.1     | 阅读 Column.vue 源码，确认 cards computed 和 onDragChange 的当前实现 | ✅   | —          | PASS     |
| 1.2     | 阅读 store.moveCard() 源码，确认其跨列处理逻辑正确                   | ✅   | —          | PASS     |
| 2.1     | 将 cards computed 替换为 ref + watch 响应式引用，移除 :list 绑定     | ✅   | Column.vue | PASS     |
| 2.2     | 定义 AddedData/MovedData/RemovedData TypeScript 接口                 | ✅   | Column.vue | PASS     |
| 2.3     | 重写 onDragChange，利用 @change 事件处理 added 和 moved 场景         | ✅   | Column.vue | PASS     |
| 2.4     | 验证模板绑定正确，移除对废弃 cards computed 的引用                   | ✅   | Column.vue | PASS     |
| 3.1-3.6 | 验证逐条映射 spec 场景                                               | ✅   | —          | PASS     |
| 3.7     | 刷新后数据保持验证                                                   | ✅   | —          | PASS     |

---

## 变更清单

### 修改文件

- `create-todos-app/src/components/Column.vue`:
  - 将 `cards` computed（setter 空函数）替换为 `columnCards` ref + watch 响应式引用
  - 新增 `AddedData`/`MovedData`/`RemovedData` TypeScript 接口定义
  - 重写 `onDragChange`：从数组长度比对改为 `@change` 事件驱动，处理 `added`（跨列移入）和 `moved`（同列重排序）
  - 模板中所有 `cards` 引用替换为 `columnCards`

---

## 编译历史

| 时间  | 任务    | 结果 | 错误数 | 说明                      |
| ----- | ------- | ---- | ------ | ------------------------- |
| 21:10 | 2.1-2.4 | ✅   | 0      | npx tsc --noEmit 一次通过 |

---

## 问题记录

无。
