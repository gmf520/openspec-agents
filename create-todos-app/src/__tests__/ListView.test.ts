import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { useTodoStore } from '../stores/todo'
import ListView from '../components/ListView.vue'

describe('ListView', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  // Task 4.4: renders cards grouped by column
  it('should render cards grouped by column with group headers', () => {
    const store = useTodoStore()
    // Set up mock data
    store.columns = [
      { id: 'col-1', title: '待办', isDefault: true, order: 0 },
      { id: 'col-2', title: '已完成', isDefault: true, order: 1 },
    ]
    store.cards = [
      {
        id: 'card-1',
        title: '任务A',
        description: '',
        columnId: 'col-1',
        priority: 'high',
        tags: [],
        dueDate: null,
        completed: false,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
        order: 0,
      },
      {
        id: 'card-2',
        title: '任务B',
        description: '',
        columnId: 'col-2',
        priority: 'low',
        tags: [],
        dueDate: null,
        completed: true,
        createdAt: '2026-01-02T00:00:00.000Z',
        updatedAt: '2026-01-02T00:00:00.000Z',
        order: 0,
      },
    ]
    store.tags = []

    const wrapper = mount(ListView)
    const groupHeaders = wrapper.findAll('.group-title')
    expect(groupHeaders).toHaveLength(2)
    expect(groupHeaders[0].text()).toBe('待办')
    expect(groupHeaders[1].text()).toBe('已完成')

    // Check card titles are rendered
    const cardTitles = wrapper.findAll('.list-card-title')
    expect(cardTitles).toHaveLength(2)
    expect(cardTitles[0].text()).toBe('任务A')
    expect(cardTitles[1].text()).toBe('任务B')
  })

  // Task 4.5: empty state with no matching cards
  it('should show empty state when no cards match filters', () => {
    const store = useTodoStore()
    store.columns = [
      { id: 'col-1', title: '待办', isDefault: true, order: 0 },
    ]
    store.cards = [
      {
        id: 'card-1',
        title: '任务A',
        description: '',
        columnId: 'col-1',
        priority: 'high',
        tags: [],
        dueDate: null,
        completed: false,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
        order: 0,
      },
    ]
    store.tags = []

    // Set filter to exclude all cards
    store.setFilter({ priority: 'low' })

    const wrapper = mount(ListView)
    expect(wrapper.text()).toContain('未找到匹配的卡片')
  })

  it('should not show empty state when cards match filters', () => {
    const store = useTodoStore()
    store.columns = [
      { id: 'col-1', title: '待办', isDefault: true, order: 0 },
    ]
    store.cards = [
      {
        id: 'card-1',
        title: '任务A',
        description: '',
        columnId: 'col-1',
        priority: 'high',
        tags: [],
        dueDate: null,
        completed: false,
        createdAt: '2026-01-01T00:00:00.000Z',
        updatedAt: '2026-01-01T00:00:00.000Z',
        order: 0,
      },
    ]
    store.tags = []

    const wrapper = mount(ListView)
    expect(wrapper.text()).not.toContain('未找到匹配的卡片')
  })
})
