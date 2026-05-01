# Todo CRUD Specification

## Purpose

TBD - 定义 Todo 卡片的创建、编辑、删除和完成状态切换的核心操作规范。

## Requirements

### Requirement: Create Todo Card
系统 SHALL 允许用户在指定看板列中创建新的 Todo 卡片。

#### Scenario: Create card with title only
- **WHEN** 用户在"待办"列点击"添加"按钮并输入标题"买菜"
- **THEN** 系统在"待办"列顶部创建新卡片，标题为"买菜"，其他字段为默认值（无优先级、无标签、无截止日期、未完成）

#### Scenario: Create card with all fields
- **WHEN** 用户创建卡片时填写标题"项目汇报"，选择优先级"高"，添加标签"工作"，设置截止日期为"2026-05-10"
- **THEN** 系统创建包含完整信息的卡片，在列顶部显示，优先级标识为红色，标签显示"工作"徽章，截止日期显示为"2026-05-10"

#### Scenario: Create card with empty title
- **WHEN** 用户点击"添加"按钮但标题为空
- **THEN** 系统阻止创建，显示"标题不能为空"的验证提示

#### Scenario: Create card with excessively long title
- **WHEN** 用户输入的标题超过 200 字符
- **THEN** 系统阻止创建，提示"标题不能超过 200 个字符"

### Requirement: Edit Todo Card
系统 SHALL 允许用户编辑已有 Todo 卡片的所有字段。

#### Scenario: Edit card title
- **WHEN** 用户点击卡片编辑按钮，打开编辑弹窗，将标题从"买菜"改为"买蔬菜和水果"
- **THEN** 系统更新卡片标题，其他字段保持不变，卡片仍在原列原位

#### Scenario: Edit card with empty title
- **WHEN** 用户在编辑弹窗中清空标题字段并保存
- **THEN** 系统阻止保存，显示"标题不能为空"的验证提示，卡片保持原有标题不变

#### Scenario: Cancel editing
- **WHEN** 用户在编辑弹窗中修改内容后点击"取消"
- **THEN** 系统关闭弹窗，卡片数据保持不变

### Requirement: Delete Todo Card
系统 SHALL 允许用户删除 Todo 卡片，并需要确认防止误操作。

#### Scenario: Delete card with confirmation
- **WHEN** 用户点击卡片的删除按钮并在确认对话框中点击"确认"
- **THEN** 系统从列中移除卡片，且数据从 localStorage 同步删除

#### Scenario: Cancel card deletion
- **WHEN** 用户点击卡片的删除按钮但在确认对话框中点击"取消"
- **THEN** 系统保留卡片，不做任何修改

### Requirement: Mark Card Complete / Uncomplete
系统 SHALL 允许用户勾选/取消勾选完成状态，自动将卡片移至对应列。

#### Scenario: Mark card as complete
- **WHEN** 用户在"待办"列勾选某卡片的完成复选框
- **THEN** 卡片从"待办"列移动到"已完成"列，`completed` 字段变为 `true`

#### Scenario: Unmark completed card
- **WHEN** 用户在"已完成"列取消勾选某卡片的完成复选框
- **THEN** 卡片从"已完成"列移回"待办"列（默认行为，后续可配置回退列）
