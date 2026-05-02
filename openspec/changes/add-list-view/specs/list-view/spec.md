# List View Specification

## Purpose

Define the card-style list view mode for the kanban Todo app, providing an alternative to the kanban board for vertical browsing.

## ADDED Requirements

### Requirement: View Mode Toggle
System SHALL allow users to toggle between kanban board view and card-style list view.

#### Scenario: Switch to list view
- **WHEN** user clicks the list view toggle button
- **THEN** view switches from kanban board to card-style list view showing all cards grouped by column

#### Scenario: Switch back to kanban view
- **WHEN** user clicks the kanban view toggle button
- **THEN** view switches back to kanban board layout

#### Scenario: Default view on first load
- **WHEN** user opens the app for the first time
- **THEN** the app defaults to kanban board view

#### Scenario: Restore view preference after refresh
- **WHEN** user was on list view, then refreshes the page
- **THEN** the app restores to list view from localStorage

#### Scenario: Backward compatibility with old data
- **WHEN** existing user data in localStorage has no viewMode field
- **THEN** the app defaults to kanban board view without errors

### Requirement: Card-Style List Display
System SHALL display all cards in a card-style list layout grouped by column, with each card showing title, description, priority, tags, due date, created date, and completed status.

#### Scenario: Display all cards in card-style list
- **WHEN** user switches to list view and there are 5 cards across different columns
- **THEN** all 5 cards appear in a card-style list grouped by column, each showing title, description, priority, tags, due date, created at, and completed status

#### Scenario: Empty list view
- **WHEN** user switches to list view but no cards exist
- **THEN** list shows no cards with a message "未找到匹配的卡片"

#### Scenario: Filtered list view
- **WHEN** user applies a priority filter in filter panel then switches to list view
- **THEN** only cards matching the filter appear in the list

#### Scenario: Collapsible column groups
- **WHEN** user clicks a column group header in list view
- **THEN** cards in that group collapse or expand accordingly

### Requirement: Inline Row Actions
System SHALL allow users to complete, edit, and delete cards directly from list view card rows.

#### Scenario: Toggle complete from list view
- **WHEN** user clicks the checkbox on a list view card for an incomplete card
- **THEN** card moves to "已完成" column, card reflects completed state

#### Scenario: Open edit modal from list view
- **WHEN** user clicks on a card title in list view
- **THEN** CardModal opens with the card data pre-filled for editing

#### Scenario: Delete card from list view
- **WHEN** user clicks delete button on a list view card and confirms
- **THEN** card is removed from the list and data is persisted

#### Scenario: Cancel delete from list view
- **WHEN** user clicks delete button but cancels the confirmation
- **THEN** card remains unchanged
