<script setup lang="ts">
import { computed, ref } from 'vue'
import { useTodoStore } from '../stores/todo'
import { formatDate, isOverdue, isDueToday } from '../utils/helpers'
import type { TodoCard } from '../types'

const store = useTodoStore()

// Collapsible group state (local, not persisted)
const collapsedGroups = ref<Set<string>>(new Set())

function toggleGroup(columnId: string) {
  const next = new Set(collapsedGroups.value)
  if (next.has(columnId)) {
    next.delete(columnId)
  } else {
    next.add(columnId)
  }
  collapsedGroups.value = next
}

function isCollapsed(columnId: string): boolean {
  return collapsedGroups.value.has(columnId)
}

// Group cards by column (status) with filtering
const groupedCards = computed(() => {
  return store.columns
    .map((col) => ({
      column: col,
      cards: store.getCardsByColumn(col.id),
    }))
    .filter((group) => group.cards.length > 0)
})

// Empty state: cards exist but none match filters
const noMatchingCards = computed(() =>
  store.cards.length > 0 && groupedCards.value.length === 0
)

function onEdit(cardId: string) {
  store.openEditModal(cardId)
}

function onDelete(cardId: string) {
  if (confirm('确定要删除这张卡片吗？')) {
    store.deleteCard(cardId)
  }
}

function onToggleComplete(cardId: string) {
  store.toggleComplete(cardId)
}

function cardDueDateClass(card: TodoCard): Record<string, boolean> {
  if (!card.dueDate || card.completed) return {}
  const overdue = isOverdue(card)
  const dueToday = isDueToday(card)
  return {
    'date-overdue': overdue,
    'date-today': dueToday && !overdue,
  }
}

function isCardOverdue(card: TodoCard): boolean {
  return isOverdue(card)
}

function isCardDueToday(card: TodoCard): boolean {
  return isDueToday(card)
}

function formatDueDate(dateStr: string | null): string {
  return formatDate(dateStr)
}

function formatCreatedAt(dateStr: string): string {
  return formatDate(dateStr)
}
</script>

<template>
  <div class="list-view">
    <!-- Empty state when no cards match filters -->
    <div v-if="noMatchingCards" class="list-empty">
      <p>未找到匹配的卡片</p>
    </div>

    <!-- Grouped cards by column -->
    <div
      v-for="group in groupedCards"
      :key="group.column.id"
      class="list-group"
    >
      <!-- Group header (click to collapse/expand) -->
      <div class="group-header" @click="toggleGroup(group.column.id)">
        <span class="group-toggle">{{ isCollapsed(group.column.id) ? '▶' : '▼' }}</span>
        <h3 class="group-title">{{ group.column.title }}</h3>
        <span class="group-count">{{ group.cards.length }}</span>
      </div>

      <!-- Group cards content (collapsible) -->
      <div v-if="!isCollapsed(group.column.id)" class="group-cards">
        <div
          v-for="card in group.cards"
          :key="card.id"
          :class="['list-card', { 'card-overdue': isCardOverdue(card) }]"
        >
          <!-- Inline complete checkbox -->
          <label class="list-card-checkbox" @click.stop>
            <input
              type="checkbox"
              :checked="card.completed"
              @change="onToggleComplete(card.id)"
            />
            <span class="checkmark"></span>
          </label>

          <!-- Card content body -->
          <div class="list-card-body">
            <div class="list-card-header">
              <!-- Title: click opens CardModal for editing -->
              <h4
                :class="['list-card-title', { completed: card.completed }]"
                @click="onEdit(card.id)"
              >
                {{ card.title }}
              </h4>

              <!-- Action buttons -->
              <div class="list-card-actions">
                <button
                  class="list-card-btn"
                  title="编辑"
                  @click.stop="onEdit(card.id)"
                >
                  ✎
                </button>
                <button
                  class="list-card-btn list-card-btn--danger"
                  title="删除"
                  @click.stop="onDelete(card.id)"
                >
                  ✕
                </button>
              </div>
            </div>

            <!-- Description -->
            <p v-if="card.description" class="list-card-description">
              {{ card.description }}
            </p>

            <!-- Meta information row -->
            <div class="list-card-meta">
              <!-- Priority badge -->
              <span :class="['priority-badge', 'priority-' + card.priority]">
                {{ { high: '高', medium: '中', low: '低', none: '无' }[card.priority] }}
              </span>

              <!-- Tags -->
              <div v-if="card.tags.length > 0" class="list-card-tags">
                <span
                  v-for="tag in card.tags"
                  :key="tag.id"
                  class="list-card-tag"
                  :style="{ background: tag.color }"
                >
                  {{ tag.name }}
                </span>
              </div>

              <!-- Due date -->
              <div
                v-if="card.dueDate"
                :class="['list-card-date', cardDueDateClass(card)]"
              >
                📅 {{ formatDueDate(card.dueDate) }}
                <span
                  v-if="isCardOverdue(card)"
                  class="date-label date-label-overdue"
                >过期</span>
                <span
                  v-else-if="isCardDueToday(card)"
                  class="date-label date-label-today"
                >今天</span>
              </div>

              <!-- Created at -->
              <span class="list-card-created">
                创建于 {{ formatCreatedAt(card.createdAt) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.list-view {
  flex: 1;
  overflow-y: auto;
  padding: 4px 0 16px;
}

/* === Empty State === */
.list-empty {
  padding: 60px 0;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 15px;
}

.list-empty p {
  margin: 0;
}

/* === Group === */
.list-group {
  margin-bottom: 16px;
}

.group-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  cursor: pointer;
  border-radius: var(--radius-md);
  background: var(--color-bg-secondary);
  user-select: none;
  transition: background 0.15s;
}

.group-header:hover {
  background: var(--color-bg-hover);
}

.group-toggle {
  font-size: 11px;
  color: var(--color-text-muted);
  flex-shrink: 0;
  width: 12px;
  text-align: center;
}

.group-title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text);
  flex: 1;
}

.group-count {
  background: var(--color-bg-hover);
  color: var(--color-text-muted);
  font-size: 12px;
  padding: 1px 8px;
  border-radius: 10px;
  flex-shrink: 0;
}

.group-cards {
  padding-top: 4px;
}

/* === List Card === */
.list-card {
  display: flex;
  gap: 10px;
  padding: 10px 12px;
  margin-top: 4px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  transition: box-shadow 0.15s;
}

.list-card:hover {
  box-shadow: var(--shadow-sm);
}

.card-overdue {
  border-color: var(--color-danger);
  border-width: 2px;
}

/* === Checkbox === */
.list-card-checkbox {
  display: flex;
  align-items: flex-start;
  cursor: pointer;
  flex-shrink: 0;
  padding-top: 2px;
}

.list-card-checkbox input {
  display: none;
}

.list-card-checkbox .checkmark {
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  display: inline-block;
  position: relative;
  transition: all 0.15s;
}

.list-card-checkbox input:checked + .checkmark {
  background: var(--color-success);
  border-color: var(--color-success);
}

.list-card-checkbox input:checked + .checkmark::after {
  content: '';
  position: absolute;
  left: 4px;
  top: 1px;
  width: 5px;
  height: 9px;
  border: solid white;
  border-width: 0 2px 2px 0;
  transform: rotate(45deg);
}

/* === Card Body === */
.list-card-body {
  flex: 1;
  min-width: 0;
}

.list-card-header {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.list-card-title {
  flex: 1;
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text);
  cursor: pointer;
  word-break: break-word;
  transition: color 0.15s;
}

.list-card-title:hover {
  color: var(--color-primary);
}

.list-card-title.completed {
  text-decoration: line-through;
  color: var(--color-text-muted);
}

.list-card-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.list-card-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px 6px;
  font-size: 14px;
  color: var(--color-text-muted);
  border-radius: 4px;
  transition: all 0.15s;
}

.list-card-btn:hover {
  background: var(--color-bg-hover);
  color: var(--color-text);
}

.list-card-btn--danger:hover {
  color: var(--color-danger);
}

/* === Description === */
.list-card-description {
  margin: 4px 0 0 0;
  font-size: 12px;
  color: var(--color-text-muted);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* === Meta Row === */
.list-card-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
}

/* === Priority Badge === */
.priority-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  font-weight: 600;
  color: #fff;
  flex-shrink: 0;
}

.priority-high {
  background: var(--priority-high);
}

.priority-medium {
  background: var(--priority-medium);
}

.priority-low {
  background: #10b981;
}

.priority-none {
  background: var(--color-text-muted);
}

/* === Tags === */
.list-card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.list-card-tag {
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  color: #fff;
  white-space: nowrap;
}

/* === Dates === */
.list-card-date {
  font-size: 12px;
  color: var(--color-text-muted);
  white-space: nowrap;
}

.date-overdue {
  color: var(--color-danger);
  font-weight: 600;
}

.date-today {
  color: var(--color-warning);
  font-weight: 600;
}

.date-label {
  font-size: 10px;
  padding: 1px 5px;
  border-radius: 3px;
  margin-left: 4px;
  color: #fff;
}

.date-label-overdue {
  background: var(--color-danger);
}

.date-label-today {
  background: var(--color-warning);
}

.list-card-created {
  font-size: 11px;
  color: var(--color-text-muted);
}
</style>
