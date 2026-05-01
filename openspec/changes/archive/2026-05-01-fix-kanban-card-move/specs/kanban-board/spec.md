## MODIFIED Requirements

### Requirement: Drag-and-Drop Cards Between Columns
系统 SHALL 支持用户通过拖拽在列间移动卡片。

#### Scenario: Drag card to another column with existing cards
- **WHEN** 用户将"待办"列中的卡片拖拽到"进行中"列（目标列已有卡片）
- **THEN** 卡片从"待办"列消失，出现在"进行中"列的目标位置，`columnId` 更新，数据持久化，其他卡片顺序保持不变

#### Scenario: Drag card to empty column
- **WHEN** 用户将卡片拖拽到一个空列
- **THEN** 卡片出现在空列中，作为该列的唯一卡片，`columnId` 更新

#### Scenario: Reorder cards within same column
- **WHEN** 用户在同一列内上下拖拽卡片，将第 3 张卡片拖到第 1 张上方
- **THEN** 系统调整卡片排序，被拖拽卡片排到第 1 位，其他卡片顺序相应上移

#### Scenario: Drag card back to original column (cancel-like move)
- **WHEN** 用户将卡片拖到目标列后，又将其拖回原列
- **THEN** 卡片回到原列的正确位置，数据正确

#### Scenario: Drag to invalid target
- **WHEN** 用户将卡片拖放到非列区域（如页面空白处）
- **THEN** 卡片回到原始位置，不发生任何变更

#### Scenario: Drag preserves source column card order
- **WHEN** 用户从"待办"列拖走一张卡片
- **THEN** 原列剩余卡片顺序正确，没有重复或丢失

#### Scenario: Refresh after drag
- **WHEN** 用户跨列拖拽卡片后刷新页面
- **THEN** 卡片保持在拖拽后的位置，`columnId` 和 `order` 已正确持久化
