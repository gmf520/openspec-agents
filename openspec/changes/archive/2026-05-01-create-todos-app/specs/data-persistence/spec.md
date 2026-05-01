## ADDED Requirements

### Requirement: Auto-Save to localStorage
系统 SHALL 在每次数据变更后自动将完整状态持久化到 localStorage。

#### Scenario: Save after creating a card
- **WHEN** 用户创建一张新卡片
- **THEN** 包含新卡片的完整应用状态自动写入 localStorage 的 `todos-app-state` 键

#### Scenario: Save after moving a card
- **WHEN** 用户将卡片从"待办"列拖拽到"进行中"列
- **THEN** 更新后的列-卡片映射关系自动写入 localStorage

#### Scenario: Save after deleting a card
- **WHEN** 用户删除一张卡片
- **THEN** 更新后的状态（不含被删除卡片）自动写入 localStorage

#### Scenario: Save after editing a card
- **WHEN** 用户修改卡片标题并保存
- **THEN** 更新后的卡片数据自动写入 localStorage

### Requirement: Load State on Startup
系统 SHALL 在应用启动时从 localStorage 加载持久化状态。

#### Scenario: Load existing data
- **WHEN** 用户刷新页面且 localStorage 中存在有效数据
- **THEN** 应用恢复上次的列、卡片、标签和筛选状态，界面与刷新前一致

#### Scenario: First launch with no data
- **WHEN** 用户首次打开应用且 localStorage 无数据
- **THEN** 应用初始化默认三列（待办/进行中/已完成）和预设标签，卡片列表为空

#### Scenario: Corrupted localStorage data
- **WHEN** localStorage 中 `todos-app-state` 数据格式损坏或不符合预期结构
- **THEN** 系统静默回退到初始默认状态（三默认列 + 预设标签 + 空卡片），不崩溃，控制台输出警告日志

#### Scenario: localStorage quota exceeded
- **WHEN** 保存数据时 localStorage 配额已满
- **THEN** 系统捕获异常，提示用户"存储空间不足，请导出数据备份后清理"

### Requirement: JSON Export/Import
系统 SHALL 提供 JSON 格式的数据导出和导入功能，作为数据备份手段。

#### Scenario: Export data to JSON
- **WHEN** 用户点击"导出数据"按钮
- **THEN** 系统生成包含 columns、cards、tags 的 JSON 文件，触发浏览器下载

#### Scenario: Import valid JSON
- **WHEN** 用户选择导入一个有效的 JSON 备份文件
- **THEN** 系统提示"导入将覆盖当前数据，是否继续？"，确认后替换全部应用状态并持久化

#### Scenario: Import invalid JSON file
- **WHEN** 用户选择导入格式不正确或缺少必要字段的 JSON 文件
- **THEN** 系统提示"文件格式错误，无法导入"，当前数据保持不变

#### Scenario: Cancel import
- **WHEN** 用户在确认导入时点击"取消"
- **THEN** 系统保持现有数据不变
