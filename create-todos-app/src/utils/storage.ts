import { type AppState, STORAGE_KEY, STORAGE_SCHEMA_VERSION } from '../types'

interface StorageData {
  version: number
  state: AppState
}

export function saveState(state: AppState): void {
  try {
    const data: StorageData = {
      version: STORAGE_SCHEMA_VERSION,
      state,
    }
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data))
  } catch (e) {
    if (e instanceof DOMException && e.name === 'QuotaExceededError') {
      alert('存储空间不足，请导出数据备份后清理')
      console.error('localStorage quota exceeded:', e)
    } else {
      console.error('Failed to save state:', e)
    }
  }
}

export function loadState(): AppState | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null

    const parsed = JSON.parse(raw)

    if (!parsed || typeof parsed !== 'object') {
      console.warn('Corrupted localStorage data: not an object')
      return null
    }

    if (parsed.version !== STORAGE_SCHEMA_VERSION) {
      console.warn(
        `Storage schema version mismatch: expected ${STORAGE_SCHEMA_VERSION}, got ${parsed.version}`
      )
      return null
    }

    const { state } = parsed as StorageData

    if (!state || !Array.isArray(state.columns) || !Array.isArray(state.cards) || !Array.isArray(state.tags)) {
      console.warn('Corrupted localStorage data: missing required arrays')
      return null
    }

    return state
  } catch (e) {
    console.warn('Corrupted localStorage data, falling back to defaults:', e)
    return null
  }
}

export function exportToJson(state: AppState): void {
  const json = JSON.stringify({ version: STORAGE_SCHEMA_VERSION, state }, null, 2)
  const blob = new Blob([json], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `kanban-todo-backup-${new Date().toISOString().slice(0, 10)}.json`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

export function importFromJson(jsonStr: string): AppState | null {
  try {
    const parsed = JSON.parse(jsonStr)

    if (!parsed || typeof parsed !== 'object') {
      alert('文件格式错误，无法导入')
      return null
    }

    if (parsed.version !== STORAGE_SCHEMA_VERSION) {
      alert(`文件版本不匹配，无法导入（文件版本: ${parsed.version}，当前版本: ${STORAGE_SCHEMA_VERSION}）`)
      return null
    }

    const { state } = parsed as StorageData

    if (!state || !Array.isArray(state.columns) || !Array.isArray(state.cards) || !Array.isArray(state.tags)) {
      alert('文件格式错误，无法导入')
      return null
    }

    return state
  } catch {
    alert('文件格式错误，无法导入')
    return null
  }
}
