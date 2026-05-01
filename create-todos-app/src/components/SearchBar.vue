<script setup lang="ts">
import { ref } from 'vue'
import { useTodoStore } from '../stores/todo'

const store = useTodoStore()
const query = ref(store.searchQuery)

function onInput() {
  store.setSearchQuery(query.value)
}

function onClear() {
  query.value = ''
  store.setSearchQuery('')
}
</script>

<template>
  <div class="search-bar">
    <div class="search-input-wrapper">
      <span class="search-icon">🔍</span>
      <input
        v-model="query"
        type="text"
        placeholder="搜索卡片（标题、描述、标签）..."
        class="search-input"
        @input="onInput"
      />
      <button v-if="query" class="search-clear" @click="onClear">✕</button>
    </div>
  </div>
</template>

<style scoped>
.search-bar {
  margin-bottom: 16px;
}

.search-input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  max-width: 480px;
}

.search-icon {
  position: absolute;
  left: 12px;
  font-size: 14px;
  pointer-events: none;
}

.search-input {
  width: 100%;
  padding: 10px 36px 10px 36px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  font-size: 14px;
  background: var(--color-surface);
  color: var(--color-text);
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px var(--color-primary-light);
}

.search-clear {
  position: absolute;
  right: 8px;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--color-text-muted);
  font-size: 14px;
  padding: 4px;
  line-height: 1;
}
</style>
