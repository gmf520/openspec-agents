<script setup lang="ts">
import { computed } from 'vue'
import { useTodoStore } from '../stores/todo'
import type { Priority } from '../types'

const store = useTodoStore()

const priorityOptions: { label: string; value: Priority | 'all' }[] = [
  { label: '全部优先级', value: 'all' },
  { label: '高', value: 'high' },
  { label: '中', value: 'medium' },
  { label: '低', value: 'low' },
  { label: '无', value: 'none' },
]

function toggleTag(tagId: string) {
  const current = [...store.filters.tagIds]
  const idx = current.indexOf(tagId)
  if (idx >= 0) {
    current.splice(idx, 1)
  } else {
    current.push(tagId)
  }
  store.setFilter({ tagIds: current })
}

const activeFilterCount = computed(() => {
  let count = 0
  if (store.filters.priority !== 'all') count++
  if (store.filters.tagIds.length > 0) count++
  if (store.filters.hasDueDate !== null) count++
  if (store.filters.isOverdue !== null) count++
  return count
})
</script>

<template>
  <div class="filter-panel">
    <div class="filter-row">
      <div class="filter-group">
        <label class="filter-label">优先级</label>
        <select
          class="filter-select"
          :value="store.filters.priority"
          @change="store.setFilter({ priority: ($event.target as HTMLSelectElement).value as Priority | 'all' })"
        >
          <option
            v-for="opt in priorityOptions"
            :key="opt.value"
            :value="opt.value"
          >
            {{ opt.label }}
          </option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label">标签</label>
        <div class="tag-chips">
          <button
            v-for="tag in store.allTags"
            :key="tag.id"
            :class="['tag-chip', { active: store.filters.tagIds.includes(tag.id) }]"
            :style="{ '--tag-color': tag.color }"
            @click="toggleTag(tag.id)"
          >
            {{ tag.name }}
          </button>
        </div>
      </div>

      <div class="filter-group">
        <label class="filter-label">截止日期</label>
        <select
          class="filter-select"
          :value="store.filters.hasDueDate === null ? 'all' : store.filters.hasDueDate ? 'yes' : 'no'"
          @change="
            (e) => {
              const val = (e.target as HTMLSelectElement).value
              store.setFilter({ hasDueDate: val === 'all' ? null : val === 'yes' })
            }
          "
        >
          <option value="all">全部</option>
          <option value="yes">有截止日期</option>
          <option value="no">无截止日期</option>
        </select>
      </div>

      <div class="filter-group">
        <label class="filter-label">过期状态</label>
        <select
          class="filter-select"
          :value="store.filters.isOverdue === null ? 'all' : store.filters.isOverdue ? 'yes' : 'no'"
          @change="
            (e) => {
              const val = (e.target as HTMLSelectElement).value
              store.setFilter({ isOverdue: val === 'all' ? null : val === 'yes' })
            }
          "
        >
          <option value="all">全部</option>
          <option value="yes">已过期</option>
          <option value="no">未过期</option>
        </select>
      </div>
    </div>

    <div class="filter-actions">
      <span v-if="activeFilterCount > 0" class="filter-count">
        {{ activeFilterCount }} 个筛选条件生效
      </span>
      <button
        v-if="activeFilterCount > 0"
        class="btn btn-sm btn-outline"
        @click="store.clearFilters()"
      >
        清除筛选
      </button>
    </div>
  </div>
</template>

<style scoped>
.filter-panel {
  margin-bottom: 16px;
  padding: 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}

.filter-row {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  align-items: flex-start;
}

.filter-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.filter-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-text-muted);
  text-transform: uppercase;
}

.filter-select {
  padding: 6px 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: 13px;
  background: var(--color-bg);
  color: var(--color-text);
  cursor: pointer;
}

.tag-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.tag-chip {
  padding: 4px 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-full);
  font-size: 12px;
  background: var(--color-bg);
  color: var(--color-text);
  cursor: pointer;
  transition: all 0.15s;
}

.tag-chip.active {
  background: var(--tag-color, var(--color-primary));
  color: #fff;
  border-color: var(--tag-color, var(--color-primary));
}

.filter-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
}

.filter-count {
  font-size: 12px;
  color: var(--color-text-muted);
}
</style>
