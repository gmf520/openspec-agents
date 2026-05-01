<script setup lang="ts">
import { useTodoStore } from '../stores/todo'
import ColumnComponent from './Column.vue'

const store = useTodoStore()

function handleRename(id: string, title: string) {
  store.renameColumn(id, title)
}

function handleDelete(id: string) {
  store.deleteColumn(id)
}
</script>

<template>
  <div class="board">
    <div class="board-scroll">
      <ColumnComponent
        v-for="col in store.columns"
        :key="col.id"
        :column="col"
        @rename="handleRename"
        @delete="handleDelete"
      />
    </div>
  </div>
</template>

<style scoped>
.board {
  flex: 1;
  overflow: hidden;
}

.board-scroll {
  display: flex;
  gap: 16px;
  overflow-x: auto;
  overflow-y: hidden;
  padding-bottom: 16px;
  align-items: flex-start;
  height: 100%;
}
</style>
