import { describe, it, expect, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useTodoStore } from '../stores/todo'
import { STORAGE_KEY, STORAGE_SCHEMA_VERSION } from '../types'

describe('todo store viewMode', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  // Task 4.1: viewMode state and setViewMode action
  it('should default to board', () => {
    const store = useTodoStore()
    expect(store.viewMode).toBe('board')
  })

  it('should change viewMode via setViewMode', () => {
    const store = useTodoStore()
    store.setViewMode('list')
    expect(store.viewMode).toBe('list')
    store.setViewMode('board')
    expect(store.viewMode).toBe('board')
  })

  // Task 4.2: localStorage persist and restore
  it('should persist viewMode to localStorage', () => {
    const store = useTodoStore()
    store.setViewMode('list')
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY)!)
    expect(saved.state.viewMode).toBe('list')
  })

  it('should restore viewMode from localStorage', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      version: STORAGE_SCHEMA_VERSION,
      state: {
        columns: [],
        cards: [],
        tags: [],
        viewMode: 'list',
      },
    }))
    const store = useTodoStore()
    expect(store.viewMode).toBe('list')
  })

  // Task 4.3: backward compatibility
  it('should default to board for old data without viewMode', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({
      version: STORAGE_SCHEMA_VERSION,
      state: {
        columns: [],
        cards: [],
        tags: [],
      },
    }))
    const store = useTodoStore()
    expect(store.viewMode).toBe('board')
  })
})
