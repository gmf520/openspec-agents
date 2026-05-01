<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useTodoStore } from '../stores/todo'
import type { Priority, Tag } from '../types'
import { TAG_COLORS } from '../types'

const props = defineProps<{
  visible: boolean
  cardId?: string | null
}>()

const emit = defineEmits<{
  close: []
  save: []
}>()

const store = useTodoStore()

const title = ref('')
const description = ref('')
const priority = ref<Priority>('none')
const selectedTags = ref<Tag[]>([])
const dueDate = ref('')

const titleError = ref('')

const isEditing = computed(() => !!props.cardId)

const defaultColumnId = computed(() => {
  const col = store.columns.find((c) => c.isDefault && c.title === '待办')
  return col?.id || store.columns[0]?.id || ''
})

const showNewTagInput = ref(false)
const newTagName = ref('')
const newTagColor = ref(TAG_COLORS[0])

watch(
  () => props.visible,
  (val) => {
    if (val) {
      if (props.cardId) {
        const card = store.cards.find((c) => c.id === props.cardId)
        if (card) {
          title.value = card.title
          description.value = card.description
          priority.value = card.priority
          selectedTags.value = [...card.tags]
          dueDate.value = card.dueDate ? card.dueDate.slice(0, 10) : ''
        }
      } else {
        resetForm()
      }
    } else {
      resetForm()
    }
  }
)

function resetForm() {
  title.value = ''
  description.value = ''
  priority.value = 'none'
  selectedTags.value = []
  dueDate.value = ''
  titleError.value = ''
  showNewTagInput.value = false
  newTagName.value = ''
}

function toggleTag(tag: Tag) {
  const idx = selectedTags.value.findIndex((t) => t.id === tag.id)
  if (idx >= 0) {
    selectedTags.value.splice(idx, 1)
  } else {
    selectedTags.value.push({ ...tag })
  }
}

function createCustomTag() {
  const name = newTagName.value.trim()
  if (!name) return

  const existing = store.tags.find((t) => t.name === name)
  if (existing) {
    alert('该标签已存在')
    return
  }

  const tag = store.addTag(name, newTagColor.value)
  selectedTags.value.push({ ...tag })
  newTagName.value = ''
  showNewTagInput.value = false
}

function handleSave() {
  titleError.value = ''

  const trimmed = title.value.trim()
  if (!trimmed) {
    titleError.value = '标题不能为空'
    return
  }
  if (trimmed.length > 200) {
    titleError.value = '标题不能超过 200 个字符'
    return
  }

  if (isEditing.value && props.cardId) {
    store.updateCard(props.cardId, {
      title: trimmed,
      description: description.value.trim(),
      priority: priority.value,
      tags: selectedTags.value,
      dueDate: dueDate.value ? new Date(dueDate.value).toISOString() : null,
    })
  } else {
    store.addCard({
      title: trimmed,
      description: description.value.trim(),
      columnId: defaultColumnId.value,
      priority: priority.value,
      tags: selectedTags.value,
      dueDate: dueDate.value ? new Date(dueDate.value).toISOString() : null,
    })
  }

  emit('save')
  emit('close')
}

function handleClose() {
  emit('close')
}
</script>

<template>
  <Teleport to="body">
    <div v-if="visible" class="modal-overlay" @click.self="handleClose">
      <div class="modal" role="dialog" aria-modal="true">
        <div class="modal-header">
          <h2 class="modal-title">{{ isEditing ? '编辑卡片' : '新建卡片' }}</h2>
          <button class="modal-close" @click="handleClose">✕</button>
        </div>

        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">标题 <span class="required">*</span></label>
            <input
              v-model="title"
              type="text"
              class="form-input"
              placeholder="输入卡片标题"
              maxlength="200"
              @keyup.enter="handleSave"
            />
            <p v-if="titleError" class="form-error">{{ titleError }}</p>
          </div>

          <div class="form-group">
            <label class="form-label">描述</label>
            <textarea
              v-model="description"
              class="form-textarea"
              placeholder="输入描述（可选）"
              rows="3"
            ></textarea>
          </div>

          <div class="form-group">
            <label class="form-label">优先级</label>
            <div class="priority-options">
              <button
                v-for="p in (['high', 'medium', 'low', 'none'] as Priority[])"
                :key="p"
                :class="['priority-btn', `priority-${p}`, { active: priority === p }]"
                @click="priority = p"
              >
                {{ { high: '高', medium: '中', low: '低', none: '无' }[p] }}
              </button>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">标签</label>
            <div class="tag-selector">
              <button
                v-for="tag in store.allTags"
                :key="tag.id"
                :class="['tag-select-btn', { active: selectedTags.some((t) => t.id === tag.id) }]"
                :style="{ '--tag-color': tag.color }"
                @click="toggleTag(tag)"
              >
                {{ tag.name }}
              </button>
              <button class="tag-select-btn tag-add-btn" @click="showNewTagInput = !showNewTagInput">
                + 新建
              </button>
            </div>
            <div v-if="showNewTagInput" class="new-tag-form">
              <input
                v-model="newTagName"
                type="text"
                class="new-tag-input"
                placeholder="标签名称"
                @keyup.enter="createCustomTag"
              />
              <div class="color-picker">
                <button
                  v-for="color in TAG_COLORS"
                  :key="color"
                  :class="['color-dot', { active: newTagColor === color }]"
                  :style="{ background: color }"
                  @click="newTagColor = color"
                ></button>
              </div>
              <button class="btn btn-sm btn-primary" @click="createCustomTag">创建</button>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">截止日期</label>
            <input v-model="dueDate" type="date" class="form-input" />
            <button
              v-if="dueDate"
              class="clear-date-btn"
              @click="dueDate = ''"
            >
              清除日期
            </button>
          </div>
        </div>

        <div class="modal-footer">
          <button class="btn btn-outline" @click="handleClose">取消</button>
          <button class="btn btn-primary" @click="handleSave">
            {{ isEditing ? '保存' : '创建' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.modal {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-xl);
  width: 100%;
  max-width: 520px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--color-border);
}

.modal-title {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: var(--color-text);
}

.modal-close {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 18px;
  color: var(--color-text-muted);
  padding: 4px 8px;
  border-radius: 4px;
  transition: all 0.15s;
}

.modal-close:hover {
  background: var(--color-bg-hover);
  color: var(--color-text);
}

.modal-body {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text);
}

.required {
  color: var(--color-danger);
}

.form-input,
.form-textarea {
  padding: 8px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: 14px;
  font-family: inherit;
  background: var(--color-bg);
  color: var(--color-text);
  outline: none;
  transition: border-color 0.2s;
}

.form-input:focus,
.form-textarea:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px var(--color-primary-light);
}

.form-textarea {
  resize: vertical;
  min-height: 60px;
}

.form-error {
  margin: 0;
  font-size: 12px;
  color: var(--color-danger);
}

.priority-options {
  display: flex;
  gap: 8px;
}

.priority-btn {
  padding: 6px 14px;
  border: 2px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: 13px;
  cursor: pointer;
  background: var(--color-bg);
  color: var(--color-text);
  transition: all 0.15s;
}

.priority-btn.priority-high.active {
  border-color: var(--priority-high);
  background: var(--priority-high);
  color: #fff;
}

.priority-btn.priority-medium.active {
  border-color: var(--priority-medium);
  background: var(--priority-medium);
  color: #fff;
}

.priority-btn.priority-low.active {
  border-color: var(--priority-low);
  background: var(--priority-low);
  color: #fff;
}

.priority-btn.priority-none.active {
  border-color: var(--color-text-muted);
  background: var(--color-bg-hover);
}

.tag-selector {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.tag-select-btn {
  padding: 4px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-full);
  font-size: 12px;
  background: var(--color-bg);
  color: var(--color-text);
  cursor: pointer;
  transition: all 0.15s;
}

.tag-select-btn.active {
  background: var(--tag-color, var(--color-primary));
  color: #fff;
  border-color: var(--tag-color, var(--color-primary));
}

.tag-add-btn {
  border-style: dashed;
  color: var(--color-text-muted);
}

.new-tag-form {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.new-tag-input {
  padding: 4px 8px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: 13px;
  width: 120px;
  outline: none;
  background: var(--color-bg);
  color: var(--color-text);
}

.color-picker {
  display: flex;
  gap: 4px;
}

.color-dot {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: 2px solid transparent;
  cursor: pointer;
  padding: 0;
  transition: border-color 0.15s;
}

.color-dot.active {
  border-color: var(--color-text);
  box-shadow: 0 0 0 2px var(--color-bg);
}

.clear-date-btn {
  background: none;
  border: none;
  color: var(--color-text-muted);
  font-size: 12px;
  cursor: pointer;
  text-decoration: underline;
  padding: 0;
  align-self: flex-start;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 12px 20px 16px;
  border-top: 1px solid var(--color-border);
}
</style>
