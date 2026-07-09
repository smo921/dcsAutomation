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
/* Uses shared classes from _components.css */
</style>
