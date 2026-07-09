<template>
  <div
    class="editor-panel"
    :class="variant && `editor-panel-${variant}`"
  >
    <!-- Header with title and optional actions -->
    <div v-if="title || $slots.headerActions" class="editor-header">
      <div class="editor-header-content">
        <span v-if="icon" class="editor-header-icon">{{ icon }}</span>
        <h3 v-if="title" class="editor-header-title">{{ title }}</h3>
      </div>
      <div v-if="$slots.headerActions" class="editor-header-actions">
        <slot name="headerActions"></slot>
      </div>
    </div>

    <!-- Toolbar (optional) -->
    <div v-if="$slots.toolbar" class="editor-toolbar">
      <slot name="toolbar"></slot>
    </div>

    <!-- Main content -->
    <div class="editor-content">
      <slot></slot>
    </div>

    <!-- Footer (optional) -->
    <div v-if="$slots.footer" class="editor-footer">
      <slot name="footer"></slot>
    </div>
  </div>
</template>

<script setup>
const props = defineProps({
  title: {
    type: String,
    default: ''
  },
  icon: {
    type: String,
    default: ''
  },
  variant: {
    type: String,
    default: '' // 'default', 'primary', 'secondary'
  }
})
</script>

<style scoped>
/* Editor Panel Header */
.editor-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border-bottom: 1px solid var(--color-border);
}

.editor-header-content {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.editor-header-icon {
  font-size: var(--font-size-lg);
  line-height: 1;
  color: var(--color-primary);
}

.editor-header-title {
  font-size: var(--font-size-md);
  font-weight: var(--font-weight-semibold);
  color: var(--color-text-4);
  margin: 0;
}

.editor-header-actions {
  display: flex;
  gap: var(--spacing-xs);
}

/* Editor Toolbar */
.editor-toolbar {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
  padding: var(--spacing-xs) var(--spacing-md);
  background: var(--color-bg-2);
  border-bottom: 1px solid var(--color-border);
}

/* Editor Content */
.editor-content {
  padding: var(--spacing-md);
  overflow-y: auto;
  flex: 1 1 auto;
  min-height: 200px;
}

/* Editor Footer */
.editor-footer {
  display: flex;
  justify-content: flex-end;
  gap: var(--spacing-sm);
  padding: var(--spacing-sm) var(--spacing-md);
  background: var(--color-bg-2);
  border-top: 1px solid var(--color-border);
}

/* Variant: Primary - accent header */
.editor-panel-primary .editor-header {
  background: var(--color-primary);
}

.editor-panel-primary .editor-header-title {
  color: white;
}

.editor-panel-primary .editor-header-icon {
  color: rgba(255, 255, 255, 0.9);
}
</style>
