import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import {
  type TodoCard,
  type Column,
  type Tag,
  type FilterState,
  type CreateCardInput,
  type UpdateCardInput,
  DEFAULT_COLUMNS,
  PRESET_TAGS,
} from '../types'
import { saveState, loadState } from '../utils/storage'
import { generateId, matchesSearch, matchesFilters } from '../utils/helpers'

export const useTodoStore = defineStore('todo', () => {
  const columns = ref<Column[]>([])
  const cards = ref<TodoCard[]>([])
  const tags = ref<Tag[]>([])
  const searchQuery = ref('')
  const filters = ref<FilterState>({
    priority: 'all',
    tagIds: [],
    hasDueDate: null,
    isOverdue: null,
  })
  const editingCardId = ref<string | null>(null)

  const allTags = computed(() => tags.value)

  function getCardsByColumn(columnId: string): TodoCard[] {
    return cards.value
      .filter((card) => card.columnId === columnId)
      .filter((card) => matchesSearch(card, searchQuery.value))
      .filter((card) => matchesFilters(card, filters.value))
      .sort((a, b) => a.order - b.order)
  }

  function loadFromStorage(): void {
    const saved = loadState()
    if (saved) {
      columns.value = saved.columns
      cards.value = saved.cards
      tags.value = saved.tags
    } else {
      columns.value = DEFAULT_COLUMNS.map((col) => ({ ...col }))
      tags.value = PRESET_TAGS.map((tag) => ({ ...tag }))
    }
  }

  function persist(): void {
    saveState({
      columns: columns.value,
      cards: cards.value,
      tags: tags.value,
    })
  }

  function addCard(input: CreateCardInput): TodoCard {
    const now = new Date().toISOString()
    const maxOrder = cards.value
      .filter((c) => c.columnId === input.columnId)
      .reduce((max, c) => Math.max(max, c.order), 0)

    const card: TodoCard = {
      id: generateId(),
      title: input.title,
      description: input.description || '',
      columnId: input.columnId,
      priority: input.priority || 'none',
      tags: input.tags || [],
      dueDate: input.dueDate || null,
      completed: false,
      createdAt: now,
      updatedAt: now,
      order: maxOrder + 1,
    }

    cards.value.push(card)
    persist()
    return card
  }

  function updateCard(id: string, input: UpdateCardInput): void {
    const index = cards.value.findIndex((c) => c.id === id)
    if (index === -1) return

    const card = cards.value[index]
    Object.assign(card, input, { updatedAt: new Date().toISOString() })
    persist()
  }

  function deleteCard(id: string): void {
    cards.value = cards.value.filter((c) => c.id !== id)
    persist()
  }

  function moveCard(cardId: string, toColumnId: string, newOrder: number): void {
    const cardIndex = cards.value.findIndex((c) => c.id === cardId)
    if (cardIndex === -1) return

    const card = cards.value[cardIndex]
    const oldColumnId = card.columnId

    card.columnId = toColumnId

    const columnCards = cards.value
      .filter((c) => c.columnId === toColumnId && c.id !== cardId)
      .sort((a, b) => a.order - b.order)

    columnCards.splice(newOrder, 0, card)
    columnCards.forEach((c, i) => {
      c.order = i
    })
    card.order = newOrder

    if (oldColumnId !== toColumnId) {
      const oldColumnCards = cards.value
        .filter((c) => c.columnId === oldColumnId && c.id !== cardId)
        .sort((a, b) => a.order - b.order)
      oldColumnCards.forEach((c, i) => {
        c.order = i
      })
    }

    persist()
  }

  function toggleComplete(cardId: string): void {
    const card = cards.value.find((c) => c.id === cardId)
    if (!card) return

    const newCompleted = !card.completed
    if (newCompleted) {
      const doneColumn = columns.value.find((c) => c.isDefault && c.title === '已完成')
      if (doneColumn) {
        moveCard(cardId, doneColumn.id, 0)
        card.completed = true
        card.updatedAt = new Date().toISOString()
      }
    } else {
      const todoColumn = columns.value.find((c) => c.isDefault && c.title === '待办')
      const targetColumn = todoColumn || columns.value[0]
      moveCard(cardId, targetColumn.id, 0)
      card.completed = false
      card.updatedAt = new Date().toISOString()
    }
    persist()
  }

  function addColumn(title: string): Column {
    const maxOrder = columns.value.reduce((max, c) => Math.max(max, c.order), 0)
    const column: Column = {
      id: generateId(),
      title,
      isDefault: false,
      order: maxOrder + 1,
    }
    columns.value.push(column)
    persist()
    return column
  }

  function renameColumn(id: string, title: string): void {
    const column = columns.value.find((c) => c.id === id)
    if (column) {
      column.title = title
      persist()
    }
  }

  function deleteColumn(id: string): boolean {
    const column = columns.value.find((c) => c.id === id)
    if (!column) return false
    if (column.isDefault) return false

    const hasCards = cards.value.some((c) => c.columnId === id)
    if (hasCards) return false

    columns.value = columns.value.filter((c) => c.id !== id)
    persist()
    return true
  }

  function addTag(name: string, color: string): Tag {
    const tag: Tag = {
      id: generateId(),
      name,
      color,
    }
    tags.value.push(tag)
    persist()
    return tag
  }

  function openEditModal(cardId: string): void {
    editingCardId.value = cardId
  }

  function closeEditModal(): void {
    editingCardId.value = null
  }

  function setSearchQuery(query: string): void {
    searchQuery.value = query
  }

  function setFilter(partial: Partial<FilterState>): void {
    Object.assign(filters.value, partial)
  }

  function clearFilters(): void {
    filters.value = {
      priority: 'all',
      tagIds: [],
      hasDueDate: null,
      isOverdue: null,
    }
  }

  function exportData(): void {
    saveState({
      columns: columns.value,
      cards: cards.value,
      tags: tags.value,
    })
  }

  function importData(importedState: { columns: Column[]; cards: TodoCard[]; tags: Tag[] }): void {
    columns.value = importedState.columns
    cards.value = importedState.cards
    tags.value = importedState.tags
    persist()
  }

  loadFromStorage()

  return {
    columns,
    cards,
    tags,
    searchQuery,
    filters,
    editingCardId,
    allTags,
    getCardsByColumn,
    loadFromStorage,
    addCard,
    updateCard,
    deleteCard,
    moveCard,
    toggleComplete,
    addColumn,
    renameColumn,
    deleteColumn,
    addTag,
    openEditModal,
    closeEditModal,
    setSearchQuery,
    setFilter,
    clearFilters,
    exportData,
    importData,
    persist,
  }
})
