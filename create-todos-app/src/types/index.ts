export type Priority = 'high' | 'medium' | 'low' | 'none'

export interface Tag {
  id: string
  name: string
  color: string
}

export interface TodoCard {
  id: string
  title: string
  description: string
  columnId: string
  priority: Priority
  tags: Tag[]
  dueDate: string | null
  completed: boolean
  createdAt: string
  updatedAt: string
  order: number
}

export interface Column {
  id: string
  title: string
  isDefault: boolean
  order: number
}

export interface FilterState {
  priority: Priority | 'all'
  tagIds: string[]
  hasDueDate: boolean | null
  isOverdue: boolean | null
}

export interface CreateCardInput {
  title: string
  description?: string
  columnId: string
  priority?: Priority
  tags?: Tag[]
  dueDate?: string | null
}

export interface UpdateCardInput {
  title?: string
  description?: string
  columnId?: string
  priority?: Priority
  tags?: Tag[]
  dueDate?: string | null
  completed?: boolean
  order?: number
}

export interface AppState {
  columns: Column[]
  cards: TodoCard[]
  tags: Tag[]
}

export const STORAGE_KEY = 'todos-app-state'
export const STORAGE_SCHEMA_VERSION = 1

export const DEFAULT_COLUMNS: Column[] = [
  { id: 'col-todo', title: '待办', isDefault: true, order: 0 },
  { id: 'col-in-progress', title: '进行中', isDefault: true, order: 1 },
  { id: 'col-done', title: '已完成', isDefault: true, order: 2 },
]

export const PRESET_TAGS: Tag[] = [
  { id: 'tag-work', name: '工作', color: '#3B82F6' },
  { id: 'tag-personal', name: '个人', color: '#10B981' },
  { id: 'tag-study', name: '学习', color: '#8B5CF6' },
  { id: 'tag-urgent', name: '紧急', color: '#EF4444' },
]

export const TAG_COLORS = [
  '#3B82F6', '#10B981', '#8B5CF6', '#EF4444',
  '#F59E0B', '#EC4899', '#06B6D4', '#84CC16',
  '#F97316', '#6366F1', '#14B8A6', '#E11D48',
]
