# Tasks: Add List View

## 1. State Management

- [x] 1.1 Add viewMode ref to todo store (default "board")
- [x] 1.2 Add setViewMode action to store
- [x] 1.3 Add viewMode to localStorage persist/restore

## 2. List View Component

- [x] 2.1 Create ListView.vue with card-style list layout (card fields: title, priority, tags, due date, created at, actions)
- [x] 2.2 Group cards by column (status), with collapsible group headers
- [x] 2.3 Implement priority badge display (high=red, medium=yellow, low=green, none=gray)
- [x] 2.4 Implement tag display with colored labels
- [x] 2.5 Implement due date formatting with overdue highlighting
- [x] 2.6 Add inline complete checkbox calling toggleComplete
- [x] 2.7 Add edit (title click opens CardModal) and delete buttons per row
- [x] 2.8 Add empty state display ("未找到匹配的卡片") when filters return no results

## 3. Integration

- [x] 3.1 Add view mode toggle buttons (board/list) in App.vue header
- [x] 3.2 Conditionally render Board.vue or ListView.vue based on viewMode
- [x] 3.3 Verify search and filter state is shared between both views
- [x] 3.4 Verify CardModal edit flows work from list view row clicks

## 4. Testing

- [x] 4.1 Unit test: todo store viewMode state and setViewMode action
- [x] 4.2 Unit test: viewMode localStorage persist and restore
- [x] 4.3 Unit test: viewMode backward compatibility (old data without viewMode defaults to "board")
- [x] 4.4 Component test: ListView renders cards grouped by column
- [x] 4.5 Component test: ListView empty state with no matching cards
- [x] 4.6 Component test: view toggle switches between Board and ListView
