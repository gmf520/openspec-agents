## Context

Current kanban-only app.

## Goals / Non-Goals

Goals: view toggle, card-style list display, search/filter integration.
Non-Goals: drag-and-drop, column sorting, batch ops, custom columns, export.

## Architecture

Current: App.vue -> Board.vue -> Column.vue -> Card.vue

New: App.vue conditionally renders Board.vue (kanban) or ListView.vue (list).

### Store additions (todo.ts)

- viewMode: ref<"board" | "list"> (default "board")
- allFilteredCards: computed that filters cards (reuses existing matchesSearch/matchesFilters)

### Data flow

SearchBar/FilterPanel -> store (filter) -> allFilteredCards -> ListView.vue

## Component Design

### ListView.vue

Props: none (reads from store).
Card fields: Title, Description, Priority, Tags, Due Date, Created At, Completed Status, Actions.
Reuses the full information display of Card.vue (card-style list, not compact table).

Row actions:
- Title click: opens CardModal for editing
- Priority: colored badge
- Tags: colored tag list
- Due date: formatted, red if overdue
- Completed: checkbox calling toggleComplete
- Delete: button calling deleteCard with confirm

Collapsible groups: Cards grouped by column (status), with group headers that can be collapsed/expanded. Expansion state local to the component (not persisted).

Empty state: "未找到匹配的卡片" when filters return no results.

## Decisions

- View toggle: App.vue conditional rendering (no vue-router needed).
- Data source: allFilteredCards computed, reuses matchesSearch/matchesFilters.
- No column sorting: excluded per REQ-01 P0 confirmation.
- viewMode persisted to localStorage per REQ-01 R7.
- Card-style list layout (not compact table): per REQ-01 confirmation.

## Risks / Trade-offs

- Toggle complete reuses existing toggleComplete, consistent with kanban behavior.
- Current scale does not need virtual scrolling.

## Rollback Plan

- This is an additive change: new ListView.vue component + store field additions.
- Rollback: remove ListView.vue, revert App.vue conditional rendering to always show Board.vue, remove viewMode from store.
- localStorage: old data without viewMode defaults to "kanban" (backward compatible). If viewMode field exists, removing it has no side effects on other persisted state.
