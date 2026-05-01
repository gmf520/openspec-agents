# 代码评审报告: fix-kanban-card-move

**评审时间:** 2026-05-01 21:22 (UTC+8)
**评审结论:** 仅有 SUGGEST 项

---

## 评审概要

| 维度              | 状态     | 问题数 |
| ----------------- | -------- | ------ |
| 1. 正确性         | ✅       | 0      |
| 2. 安全性         | ✅       | 0      |
| 3. 性能           | ✅       | 0      |
| 4. 可维护性       | ⚠️       | 3      |
| 5. 一致性         | ⚠️       | 1      |
| 6. 测试覆盖       | ✅       | 0      |
| 7. 任务完成度     | ✅       | 0      |
| 8. 编译与类型安全 | ✅       | 0      |

---

## MUST_FIX 项

无。

所有审查维度中未发现必须修复的真问题。

---

## SUGGEST 项

### SG-001: `removed` 分支缺乏显式注释，可能导致后续维护者困惑

- **文件:** `create-todos-app/src/components/Column.vue`
- **行号:** L97-L106
- **描述:** `onDragChange` 函数中 `removed` 事件被隐式忽略（落入函数末尾），但没有任何注释说明这是有意为之。根据 `design.md` 的分析，跨列拖拽时源列触发 `removed` 而目标列触发 `added`，源列的 `removed` 之所以忽略，是因为 `store.moveCard` 已自带源列顺序修正逻辑。此设计决策在代码中没有留痕，新维护者可能误以为 `removed` 处理被遗忘。
- **建议:** 在函数末尾显式添加 `removed` 的忽略说明，或增加守卫判断：

```typescript
function onDragChange(evt: { added?: AddedData; moved?: MovedData; removed?: RemovedData }) {
  if (evt.added) {
    store.moveCard(evt.added.element.id, props.column.id, evt.added.newIndex)
    return
  }
  if (evt.moved) {
    store.moveCard(evt.moved.element.id, props.column.id, evt.moved.newIndex)
    return
  }
  // removed 由 target 列的 added 对称处理，store.moveCard 内部已处理源列 order 更新
}
```

### SG-002: watch 回调在 setup 阶段会产生一次冗余赋值

- **文件:** `create-todos-app/src/components/Column.vue`
- **行号:** L25-L29
- **描述:** `columnCards` ref 在初始化时已赋值 `store.getCardsByColumn(props.column.id)`，而 `watch` 的 `{ immediate: true }` 又会在 setup 阶段立即再次触发，给 `columnCards.value` 赋上同一个数组引用。这导致 setup 阶段有一次无意义的赋值操作。虽然不是功能性 bug，但属于微小冗余。
- **建议:** 可考虑移除 `{ immediate: true }`，但这会改变行为——如果 store 在首次渲染前已异步初始化完成，watch 将不会触发。当前方案（保留 immediate）更健壮，冗余赋值影响极小，此建议仅作知悉。

### SG-003: 接口定义中 `element` 类型过于宽泛，未与项目已有的 `TodoCard` 类型关联

- **文件:** `create-todos-app/src/components/Column.vue`
- **行号:** L31-L45
- **描述:** `AddedData`、`MovedData`、`RemovedData` 接口的 `element` 字段类型定义为 `{ id: string }`。虽然当前仅使用 `element.id`，但从类型系统的角度，`element` 的实际运行时类型是 `TodoCard`（vuedraggable 指向卡片数据）。使用最小类型定义没有功能问题，但与项目已有的 `TodoCard` 类型缺乏关联，当未来的维护者需要访问 `element` 的其他字段时会缺少类型提示。
- **建议:** 将 `element` 类型改为引入的 `TodoCard` 类型，以获得完整的类型推导：

```typescript
import type { TodoCard } from '../types'

interface AddedData {
  element: TodoCard
  newIndex: number
}
// ... 其余接口同理
```

### SG-004: `RemovedData` 接口已定义但未被显式引用

- **文件:** `create-todos-app/src/components/Column.vue`
- **行号:** L42-L45
- **描述:** `RemovedData` 在 `onDragChange` 参数类型中有用到（作为可选属性），但在函数的执行逻辑中 `removed` 分支被彻底忽略。虽然类型标注本身完整正确，但可以考虑是否真的需要在类型中标明 `removed`（从接口契约角度保留是有益的，仅作提醒）。

---

## 总体评价

代码质量优秀，正确实现了 design.md 中设计的方案。将 `cards` computed 替换为 `ref + watch`、重写 `onDragChange` 为 `@change` 事件驱动、以及模板中所有引用的替换，均逻辑完整且类型安全。无任何正确性、安全性、性能方面的真问题。4 个 SUGGEST 项均为可维护性/一致性的温和建议，不阻塞流程推进。
