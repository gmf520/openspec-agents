<script setup lang="ts">
import { ref, watch } from 'vue'
import { useTodoStore } from './stores/todo'
import { loadState, exportToJson, importFromJson } from './utils/storage'
import SearchBar from './components/SearchBar.vue'
import FilterPanel from './components/FilterPanel.vue'
import Board from './components/Board.vue'
import CardModal from './components/CardModal.vue'

const store = useTodoStore()

const showModal = ref(false)
const showNewColumnInput = ref(false)
const newColumnName = ref('')
const showImportConfirm = ref(false)
const pendingImportData = ref<ReturnType<typeof loadState> | null>(null)

watch(
  () => store.editingCardId,
  (val) => {
    if (val !== null) {
      showModal.value = true
    }
  }
)

function handleAddCard() {
  store.closeEditModal()
  showModal.value = true
}

function handleCloseModal() {
  showModal.value = false
  store.closeEditModal()
}

function handleSaveModal() {
  showModal.value = false
  store.closeEditModal()
}

function handleAddColumn() {
  const name = newColumnName.value.trim()
  if (!name) {
    alert('列名不能为空')
    return
  }
  store.addColumn(name)
  newColumnName.value = ''
  showNewColumnInput.value = false
}

function handleExport() {
  exportToJson({
    columns: store.columns,
    cards: store.cards,
    tags: store.tags,
  })
}

function handleImport() {
  const input = document.createElement('input')
  input.type = 'file'
  input.accept = '.json'
  input.onchange = async (e) => {
    const file = (e.target as HTMLInputElement).files?.[0]
    if (!file) return

    const text = await file.text()
    const imported = importFromJson(text)
    if (imported) {
      pendingImportData.value = imported
      showImportConfirm.value = true
    }
  }
  input.click()
}

function confirmImport() {
  if (pendingImportData.value) {
    store.importData(pendingImportData.value)
    pendingImportData.value = null
    showImportConfirm.value = false
  }
}

function cancelImport() {
  pendingImportData.value = null
  showImportConfirm.value = false
}

const noResults = store.cards.length > 0 && store.columns.every(
  (col) => store.getCardsByColumn(col.id).length === 0
)
</script>

<template>
  <div class="app">
    <header class="app-header">
      <div class="header-left">
        <h1 class="app-title">📋 看板 Todo</h1>
        <span class="app-subtitle">高效管理你的个人任务</span>
      </div>
      <div class="header-right">
        <button class="btn btn-sm btn-outline" @click="handleImport">📥 导入</button>
        <button class="btn btn-sm btn-outline" @click="handleExport">📤 导出</button>
      </div>
    </header>

    <main class="app-main">
      <SearchBar />
      <FilterPanel />

      <div class="board-toolbar">
        <button class="btn btn-primary" @click="handleAddCard">
          + 新建卡片
        </button>
        <div v-if="showNewColumnInput" class="new-column-form">
          <input
            v-model="newColumnName"
            type="text"
            placeholder="输入列名..."
            class="new-column-input"
            @keyup.enter="handleAddColumn"
            @keyup.escape="showNewColumnInput = false"
            autofocus
          />
          <button class="btn btn-sm btn-primary" @click="handleAddColumn">确认</button>
          <button class="btn btn-sm btn-outline" @click="showNewColumnInput = false">取消</button>
        </div>
        <button v-else class="btn btn-outline" @click="showNewColumnInput = true">
          + 添加列
        </button>
      </div>

      <div v-if="noResults" class="no-results">
        <p>未找到匹配的卡片</p>
      </div>

      <Board />
    </main>

    <CardModal
      :visible="showModal"
      :card-id="store.editingCardId"
      @close="handleCloseModal"
      @save="handleSaveModal"
    />

    <Teleport to="body">
      <div v-if="showImportConfirm" class="modal-overlay">
        <div class="modal" role="dialog" aria-modal="true">
          <div class="modal-header">
            <h3 class="modal-title">确认导入</h3>
          </div>
          <div class="modal-body">
            <p>导入将覆盖当前数据，是否继续？</p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-outline" @click="cancelImport">取消</button>
            <button class="btn btn-primary" @click="confirmImport">确认导入</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  background: var(--color-bg);
  color: var(--color-text);
}

.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  flex-shrink: 0;
}

.header-left {
  display: flex;
  align-items: baseline;
  gap: 12px;
}

.app-title {
  margin: 0;
  font-size: 20px;
  font-weight: 700;
}

.app-subtitle {
  font-size: 13px;
  color: var(--color-text-muted);
}

.header-right {
  display: flex;
  gap: 8px;
}

.app-main {
  padding: 16px 24px;
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.board-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
}

.new-column-form {
  display: flex;
  align-items: center;
  gap: 6px;
}

.new-column-input {
  padding: 6px 10px;
  border: 2px solid var(--color-primary);
  border-radius: var(--radius-sm);
  font-size: 13px;
  width: 160px;
  outline: none;
  background: var(--color-surface);
  color: var(--color-text);
}

.no-results {
  padding: 40px 0;
  text-align: center;
  color: var(--color-text-muted);
  font-size: 15px;
}

.no-results p {
  margin: 0;
}
</style>
