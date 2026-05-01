## ADDED Requirements

### Requirement: Kanban Board Default Columns
系统 SHALL 提供默认三列看板布局：待办、进行中、已完成。

#### Scenario: Initial board display
- **WHEN** 用户首次打开应用（无历史数据）
- **THEN** 看板显示三个默认列：待办、进行中、已完成，每列为空

#### Scenario: Board with existing data
- **WHEN** 用户打开应用且有 localStorage 历史数据
- **THEN** 看板恢复上次的所有列和卡片布局

### Requirement: Drag-and-Drop Cards Between Columns
系统 SHALL 支持用户通过拖拽在列间移动卡片。

#### Scenario: Drag card to another column
- **WHEN** 用户将"待办"列中的卡片拖拽到"进行中"列
- **THEN** 卡片从"待办"列消失，出现在"进行中"列的目标位置，`columnId` 更新，数据持久化

#### Scenario: Reorder cards within same column
- **WHEN** 用户在同一列内上下拖拽卡片，将第 3 张卡片拖到第 1 张上方
- **THEN** 系统调整卡片排序，被拖拽卡片排到第 1 位，其他卡片顺序相应上移

#### Scenario: Drag to invalid target
- **WHEN** 用户将卡片拖放到非列区域（如页面空白处）
- **THEN** 卡片回到原始位置，不发生任何变更

### Requirement: Custom Column Management
系统 SHALL 允许用户新增、重命名和删除自定义列，默认列不可删除。

#### Scenario: Add custom column
- **WHEN** 用户点击"添加列"按钮，输入列名"Review"，点击确认
- **THEN** 看板新增"Review"列，显示在最右侧，`isDefault` 为 `false`

#### Scenario: Rename custom column
- **WHEN** 用户双击"Review"列标题，输入新名称"Code Review"，确认
- **THEN** 列标题更新为"Code Review"

#### Scenario: Delete custom column with cards
- **WHEN** 用户尝试删除包含卡片的"Review"列
- **THEN** 系统提示"该列包含卡片，请先移动或删除卡片"，阻止删除操作

#### Scenario: Delete empty custom column
- **WHEN** 用户删除空的自定义列
- **THEN** 系统移除该列，数据从 localStorage 同步删除

#### Scenario: Delete default column
- **WHEN** 用户尝试删除"待办"列
- **THEN** 删除按钮不可用或系统提示"默认列不可删除"，列保持不变

#### Scenario: Empty column name
- **WHEN** 用户新增或重命名列时输入空名称
- **THEN** 系统阻止操作，提示"列名不能为空"
