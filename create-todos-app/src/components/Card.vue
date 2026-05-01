<script setup lang="ts">
import { computed } from 'vue'
import type { TodoCard } from '../types'
import { isOverdue, isDueToday, formatDate } from '../utils/helpers'

const props = defineProps<{
  card: TodoCard
}>()

const emit = defineEmits<{
  edit: [id: string]
  delete: [id: string]
  'toggle-complete': [id: string]
}>()

const overdue = computed(() => isOverdue(props.card))
const dueToday = computed(() => isDueToday(props.card))


const dateClass = computed(() => ({
  'due-overdue': overdue.value,
  'due-today': dueToday.value && !overdue.value,
}))

const cardClass = computed(() => ({
  'card--overdue': overdue.value,
  ['priority-' + props.card.priority]: true,
}))
</script>

<template>
  <div :class="['card', cardClass]">
    <div class="card-priority-bar"></div>
    <div class="card-body">
      <div class="card-header">
        <label class="card-checkbox" @click.stop>
          <input
            type="checkbox"
            :checked="card.completed"
            @change="emit('toggle-complete', card.id)"
          />
          <span class="checkmark"></span>
        </label>
        <h4 :class="['card-title', { completed: card.completed }]">
          {{ card.title }}
        </h4>
        <div class="card-actions">
          <button class="card-btn" title="编辑" @click="emit('edit', card.id)">✎</button>
          <button class="card-btn card-btn--danger" title="删除" @click="emit('delete', card.id)">✕</button>
        </div>
      </div>

      <p v-if="card.description" class="card-description">{{ card.description }}</p>

      <div class="card-meta">
        <div v-if="card.tags.length > 0" class="card-tags">
          <span
            v-for="tag in card.tags"
            :key="tag.id"
            class="card-tag"
            :style="{ background: tag.color }"
          >
            {{ tag.name }}
          </span>
        </div>
        <div v-if="card.dueDate" :class="['card-due-date', dateClass]">
          📅 {{ formatDate(card.dueDate) }}
          <span v-if="overdue" class="overdue-label">过期</span>
          <span v-else-if="dueToday" class="due-today-label">今天</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  margin-bottom: 8px;
  overflow: hidden;
  transition: box-shadow 0.2s, transform 0.15s;
  display: flex;
  cursor: grab;
}

.card:hover {
  box-shadow: var(--shadow-md);
}

.card:active {
  cursor: grabbing;
}

.card--overdue {
  border-color: var(--color-danger);
  border-width: 2px;
}

.card-priority-bar {
  width: 4px;
  flex-shrink: 0;
}

.priority-high .card-priority-bar {
  background: var(--priority-high);
}

.priority-medium .card-priority-bar {
  background: var(--priority-medium);
}

.priority-low .card-priority-bar {
  background: var(--priority-low);
}

.priority-none .card-priority-bar {
  background: transparent;
}

.card-body {
  padding: 10px 12px;
  flex: 1;
  min-width: 0;
}

.card-header {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.card-checkbox {
  display: flex;
  align-items: center;
  cursor: pointer;
  flex-shrink: 0;
  margin-top: 2px;
}

.card-checkbox input {
  display: none;
}

.checkmark {
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-radius: 4px;
  display: inline-block;
  position: relative;
  transition: all 0.15s;
}

.card-checkbox input:checked + .checkmark {
  background: var(--color-success);
  border-color: var(--color-success);
}

.card-checkbox input:checked + .checkmark::after {
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

.card-title {
  flex: 1;
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text);
  word-break: break-word;
}

.card-title.completed {
  text-decoration: line-through;
  color: var(--color-text-muted);
}

.card-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.15s;
}

.card:hover .card-actions {
  opacity: 1;
}

.card-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px 6px;
  font-size: 14px;
  color: var(--color-text-muted);
  border-radius: 4px;
  transition: all 0.15s;
}

.card-btn:hover {
  background: var(--color-bg-hover);
  color: var(--color-text);
}

.card-btn--danger:hover {
  color: var(--color-danger);
}

.card-description {
  margin: 6px 0 0 0;
  font-size: 12px;
  color: var(--color-text-muted);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.card-meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
}

.card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.card-tag {
  padding: 2px 8px;
  border-radius: 10px;
  font-size: 11px;
  color: #fff;
  white-space: nowrap;
}

.card-due-date {
  font-size: 12px;
  color: var(--color-text-muted);
}

.due-today {
  color: var(--color-warning);
  font-weight: 600;
}

.due-overdue {
  color: var(--color-danger);
  font-weight: 600;
}

.overdue-label,
.due-today-label {
  font-size: 10px;
  padding: 1px 5px;
  border-radius: 3px;
  margin-left: 4px;
}

.overdue-label {
  background: var(--color-danger);
  color: #fff;
}

.due-today-label {
  background: var(--color-warning);
  color: #fff;
}
</style>
