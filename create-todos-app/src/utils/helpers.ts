import { v4 as uuidv4 } from 'uuid'
import { type TodoCard, type FilterState } from '../types'

export function generateId(): string {
  return uuidv4()
}

export function isOverdue(card: TodoCard): boolean {
  if (!card.dueDate || card.completed) return false
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const dueDate = new Date(card.dueDate)
  dueDate.setHours(0, 0, 0, 0)
  return dueDate < today
}

export function isDueToday(card: TodoCard): boolean {
  if (!card.dueDate || card.completed) return false
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const dueDate = new Date(card.dueDate)
  dueDate.setHours(0, 0, 0, 0)
  return dueDate.getTime() === today.getTime()
}

export function matchesSearch(card: TodoCard, query: string): boolean {
  if (!query.trim()) return true
  const lowerQuery = query.toLowerCase()
  return (
    card.title.toLowerCase().includes(lowerQuery) ||
    card.description.toLowerCase().includes(lowerQuery) ||
    card.tags.some((tag) => tag.name.toLowerCase().includes(lowerQuery))
  )
}

export function matchesFilters(card: TodoCard, filters: FilterState): boolean {
  if (filters.priority !== 'all' && card.priority !== filters.priority) {
    return false
  }

  if (filters.tagIds.length > 0) {
    const cardTagIds = card.tags.map((t) => t.id)
    if (!filters.tagIds.every((id) => cardTagIds.includes(id))) {
      return false
    }
  }

  if (filters.hasDueDate === true && !card.dueDate) {
    return false
  }
  if (filters.hasDueDate === false && card.dueDate) {
    return false
  }

  if (filters.isOverdue === true && (!card.dueDate || !isOverdue(card))) {
    return false
  }
  if (filters.isOverdue === false && card.dueDate && isOverdue(card)) {
    return false
  }

  return true
}

export function formatDate(dateStr: string | null): string {
  if (!dateStr) return ''
  const date = new Date(dateStr)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}
