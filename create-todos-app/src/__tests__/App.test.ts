import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { useTodoStore } from '../stores/todo'
import App from '../App.vue'

describe('App view toggle', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
  })

  // Task 4.6: view toggle switches between Board and ListView
  it('should default to board view', () => {
    const wrapper = mount(App)
    // Board component should be present
    expect(wrapper.findComponent({ name: 'Board' }).exists()).toBe(true)
    // ListView component should not be present
    expect(wrapper.findComponent({ name: 'ListView' }).exists()).toBe(false)
  })

  it('should switch to list view when list toggle is clicked', async () => {
    const wrapper = mount(App)
    const store = useTodoStore()

    // Find and click the list toggle button
    const toggleButtons = wrapper.findAll('.toggle-btn')
    expect(toggleButtons).toHaveLength(2)

    // Click the "列表" (list) button
    await toggleButtons[1].trigger('click')

    // Verify store was updated
    expect(store.viewMode).toBe('list')

    // Re-render to check components
    await wrapper.vm.$nextTick()
    expect(wrapper.findComponent({ name: 'Board' }).exists()).toBe(false)
    expect(wrapper.findComponent({ name: 'ListView' }).exists()).toBe(true)
  })

  it('should switch back to board view when board toggle is clicked', async () => {
    const wrapper = mount(App)
    const store = useTodoStore()

    // First switch to list
    store.setViewMode('list')
    await wrapper.vm.$nextTick()

    // Then switch back to board
    const toggleButtons = wrapper.findAll('.toggle-btn')
    await toggleButtons[0].trigger('click')

    expect(store.viewMode).toBe('board')
    await wrapper.vm.$nextTick()
    expect(wrapper.findComponent({ name: 'Board' }).exists()).toBe(true)
    expect(wrapper.findComponent({ name: 'ListView' }).exists()).toBe(false)
  })
})
