<script setup lang="ts">
import { ref, watch } from 'vue'
import draggable from 'vuedraggable'
import type { Column } from '../types'
import { useTodoStore } from '../stores/todo'
import CardComponent from './Card.vue'

const props = defineProps<{
  column: Column
}>()

const store = useTodoStore()

const emit = defineEmits<{
  rename: [id: string, title: string]
  delete: [id: string]
}>()

const isEditing = ref(false)
const editTitle = ref(props.column.title)
const showAddForm = ref(false)
const newCardTitle = ref('')
const newCardTitleError = ref('')

const columnCards = ref(store.getCardsByColumn(props.column.id))

watch(() => store.getCardsByColumn(props.column.id), (newCards) => {
  columnCards.value = newCards
}, { immediate: true })

interface AddedData {
  element: { id: string }
  newIndex: number
}

interface MovedData {
  element: { id: string }
  oldIndex: number
  newIndex: number
}

interface RemovedData {
  element: { id: string }
  oldIndex: number
}

function startRename() {
  editTitle.value = props.column.title
  isEditing.value = true
}

function confirmRename() {
  const trimmed = editTitle.value.trim()
  if (!trimmed) {
    alert('列名不能为空')
    return
  }
  emit('rename', props.column.id, trimmed)
  isEditing.value = false
}

function cancelRename() {
  isEditing.value = false
}

function onDeleteColumn() {
  if (props.column.isDefault) {
    alert('默认列不可删除')
    return
  }
  const hasCards = store.cards.some((c) => c.columnId === props.column.id)
  if (hasCards) {
    alert('该列包含卡片，请先移动或删除卡片')
    return
  }
  emit('delete', props.column.id)
}

function handleAddCard() {
  const trimmed = newCardTitle.value.trim()
  newCardTitleError.value = ''

  if (!trimmed) {
    newCardTitleError.value = '标题不能为空'
    return
  }
  if (trimmed.length > 200) {
    newCardTitleError.value = '标题不能超过 200 个字符'
    return
  }

  store.addCard({ title: trimmed, columnId: props.column.id })
  newCardTitle.value = ''
  showAddForm.value = false
}

function onDragChange(evt: { added?: AddedData; moved?: MovedData; removed?: RemovedData }) {
  if (evt.added) {
    store.moveCard(evt.added.element.id, props.column.id, evt.added.newIndex)
    return
  }
  if (evt.moved) {
    store.moveCard(evt.moved.element.id, props.column.id, evt.moved.newIndex)
    return
  }
}

function onCardEdit(cardId: string) {
  store.openEditModal(cardId)
}

function onCardDelete(cardId: string) {
  if (confirm('确定要删除这张卡片吗？')) {
    store.deleteCard(cardId)
  }
}

function onToggleComplete(cardId: string) {
  store.toggleComplete(cardId)
}
</script>

<template>
  <div class="column">
    <div class="column-header">
      <div v-if="!isEditing" class="column-title-wrapper" @dblclick="startRename">
        <h3 class="column-title">{{ column.title }}</h3>
        <span class="column-count">{{ columnCards.length }}</span>
      </div>
      <div v-else class="column-edit">
        <input
          v-model="editTitle"
          type="text"
          class="column-edit-input"
          @keyup.enter="confirmRename"
          @keyup.escape="cancelRename"
          @blur="confirmRename"
          autofocus
        />
      </div>
      <div class="column-header-actions">
        <button class="column-btn" title="重命名" @click="startRename">✎</button>
        <button
          v-if="!column.isDefault"
          class="column-btn column-btn--danger"
          title="删除列"
          @click="onDeleteColumn"
        >
          ✕
        </button>
      </div>
    </div>

    <draggable
      :list="columnCards"
      group="cards"
      item-key="id"
      class="column-cards"
      ghost-class="ghost-card"
      :animation="200"
      @change="onDragChange"
    >
      <template #item="{ element }">
        <CardComponent
          :card="element"
          @edit="onCardEdit"
          @delete="onCardDelete"
          @toggle-complete="onToggleComplete"
        />
      </template>
    </draggable>

    <div v-if="columnCards.length === 0" class="column-empty">
      <p>暂无卡片</p>
    </div>

    <div class="column-footer">
      <button v-if="!showAddForm" class="add-card-btn" @click="showAddForm = true">
        + 添加卡片
      </button>
      <div v-else class="add-card-form">
        <input
          v-model="newCardTitle"
          type="text"
          placeholder="输入卡片标题..."
          class="add-card-input"
          @keyup.enter="handleAddCard"
          @keyup.escape="showAddForm = false"
          autofocus
        />
        <p v-if="newCardTitleError" class="add-card-error">{{ newCardTitleError }}</p>
        <div class="add-card-actions">
          <button class="btn btn-sm btn-primary" @click="handleAddCard">添加</button>
          <button class="btn btn-sm btn-outline" @click="showAddForm = false; newCardTitle = ''; newCardTitleError = ''">
            取消
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.column {
  min-width: 280px;
  max-width: 320px;
  width: 300px;
  flex-shrink: 0;
  background: var(--color-bg-secondary);
  border-radius: var(--radius-lg);
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 200px);
}

.column-header {
  padding: 12px 14px 8px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.column-title-wrapper {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  cursor: pointer;
  min-width: 0;
}

.column-title {
  margin: 0;
  font-size: 15px;
  font-weight: 600;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.column-count {
  background: var(--color-bg-hover);
  color: var(--color-text-muted);
  font-size: 12px;
  padding: 1px 8px;
  border-radius: 10px;
  flex-shrink: 0;
}

.column-edit {
  flex: 1;
}

.column-edit-input {
  width: 100%;
  padding: 4px 8px;
  border: 2px solid var(--color-primary);
  border-radius: var(--radius-sm);
  font-size: 15px;
  font-weight: 600;
  outline: none;
  background: var(--color-surface);
  color: var(--color-text);
}

.column-header-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
}

.column-btn {
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px 5px;
  font-size: 13px;
  color: var(--color-text-muted);
  border-radius: 4px;
  transition: all 0.15s;
}

.column-btn:hover {
  background: var(--color-bg-hover);
  color: var(--color-text);
}

.column-btn--danger:hover {
  color: var(--color-danger);
}

.column-cards {
  padding: 4px 10px;
  overflow-y: auto;
  flex: 1;
  min-height: 60px;
}

.ghost-card {
  opacity: 0.4;
  background: var(--color-primary-light);
}

.column-empty {
  padding: 20px 10px;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 13px;
}

.column-footer {
  padding: 8px 10px;
  border-top: 1px solid var(--color-border);
}

.add-card-btn {
  width: 100%;
  padding: 8px;
  background: none;
  border: 1px dashed var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-text-muted);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}

.add-card-btn:hover {
  background: var(--color-bg-hover);
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.add-card-form {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.add-card-input {
  width: 100%;
  padding: 8px;
  border: 2px solid var(--color-primary);
  border-radius: var(--radius-sm);
  font-size: 13px;
  outline: none;
  background: var(--color-surface);
  color: var(--color-text);
  box-sizing: border-box;
}

.add-card-error {
  margin: 0;
  font-size: 12px;
  color: var(--color-danger);
}

.add-card-actions {
  display: flex;
  gap: 6px;
}
</style>
