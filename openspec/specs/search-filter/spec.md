# Search & Filter Specification

## Purpose

TBD - 定义卡片的优先级标记、标签管理、截止日期提示，以及关键词搜索和组合筛选功能规范。

## Requirements

### Requirement: Priority Marking
系统 SHALL 支持 Todo 卡片的优先级标记，并以颜色可视化标识。

#### Scenario: Set card priority to high
- **WHEN** 用户创建/编辑卡片时选择优先级"高"
- **THEN** 卡片左侧显示红色优先级条，其他用户可一眼识别

#### Scenario: Set card priority to medium
- **WHEN** 用户创建/编辑卡片时选择优先级"中"
- **THEN** 卡片左侧显示橙色优先级条

#### Scenario: Set card priority to low
- **WHEN** 用户创建/编辑卡片时选择优先级"低"
- **THEN** 卡片左侧显示灰色优先级条

#### Scenario: Default priority is none
- **WHEN** 用户创建卡片时未选择优先级
- **THEN** 卡片无优先级标识，`priority` 为 `"none"`

### Requirement: Tags/Categories
系统 SHALL 支持标签管理，卡片可关联多个标签。

#### Scenario: Add tags to card
- **WHEN** 用户编辑卡片时从预设标签中选择"工作"和"紧急"
- **THEN** 卡片上显示两个标签徽章（"工作"和"紧急"），使用各自对应的颜色

#### Scenario: Create custom tag
- **WHEN** 用户在标签选择器中输入新标签名"设计"并选择颜色 `#8B5CF6`
- **THEN** 新标签"设计"被创建，用户可将其分配给卡片

#### Scenario: Preset tags available
- **WHEN** 用户首次打开应用
- **THEN** 系统预设标签已存在：工作、个人、学习、紧急，各有默认颜色

#### Scenario: Remove tag from card
- **WHEN** 用户编辑卡片时取消选中"工作"标签
- **THEN** 卡片上不再显示"工作"标签徽章

### Requirement: Due Date
系统 SHALL 支持为卡片设置截止日期，并对过期和即将到期的卡片进行视觉提示。

#### Scenario: Set due date
- **WHEN** 用户创建/编辑卡片时设置截止日期为"2026-05-10"
- **THEN** 卡片底部显示"截止：2026-05-10"

#### Scenario: Overdue card highlight
- **WHEN** 当前日期为 2026-05-11，某卡片截止日期为 2026-05-10
- **THEN** 卡片截止日期文字显示为红色，卡片整体有红色边框警示

#### Scenario: Due today highlight
- **WHEN** 当前日期为 2026-05-10，某卡片截止日期为 2026-05-10
- **THEN** 卡片截止日期文字显示为黄色/橙色，提示即将到期

#### Scenario: Clear due date
- **WHEN** 用户编辑卡片时清除截止日期字段
- **THEN** 卡片不再显示截止日期信息

### Requirement: Keyword Search
系统 SHALL 支持关键词实时搜索，在标题、描述和标签名中匹配。

#### Scenario: Search by title
- **WHEN** 用户在搜索框输入"项目"
- **THEN** 所有列中标题包含"项目"的卡片保持可见，不匹配的卡片被隐藏

#### Scenario: Search by tag name
- **WHEN** 用户在搜索框输入"工作"
- **THEN** 标题或标签名包含"工作"的卡片保持可见

#### Scenario: Search with no results
- **WHEN** 用户输入"xyz123"且无任何卡片匹配
- **THEN** 所有列显示为空，看板显示"未找到匹配的卡片"提示

#### Scenario: Clear search
- **WHEN** 用户清空搜索框
- **THEN** 所有卡片恢复可见，筛选条件（如有）继续生效

### Requirement: Combined Filtering
系统 SHALL 支持多条件组合筛选。

#### Scenario: Filter by priority
- **WHEN** 用户选择筛选条件"优先级=高"
- **THEN** 所有列仅显示优先级为"高"的卡片

#### Scenario: Filter by tags
- **WHEN** 用户选择筛选标签"工作"和"紧急"
- **THEN** 所有列仅显示同时包含"工作"和"紧急"标签的卡片

#### Scenario: Filter by due date status
- **WHEN** 用户选择筛选"仅显示有截止日期的卡片"
- **THEN** 所有列仅显示 `dueDate` 不为空的卡片

#### Scenario: Filter by overdue
- **WHEN** 用户选择筛选"仅显示已过期的卡片"
- **THEN** 所有列仅显示截止日期早于今天且未完成的卡片

#### Scenario: Combined search and filter
- **WHEN** 用户搜索"项目"且筛选"优先级=高"
- **THEN** 所有列仅显示标题或标签包含"项目"且优先级为"高"的卡片

#### Scenario: Clear all filters
- **WHEN** 用户点击"清除筛选"按钮
- **THEN** 所有筛选条件重置为默认值，所有卡片恢复可见
