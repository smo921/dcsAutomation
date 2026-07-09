<template>
  <div class="collapsible-section">
    <div class="section-header" @click="toggle">
      <h3 class="section-title">{{ title }}</h3>
      <span class="toggle-icon" :class="{ expanded: internalExpanded }">▼</span>
    </div>
    <div v-if="internalExpanded" class="section-content">
      <slot></slot>
    </div>
  </div>
</template>

<script>
import { ref, watch } from 'vue'

export default {
  name: 'CollapsibleSection',
  props: {
    title: {
      type: String,
      default: ''
    },
    expanded: {
      type: Boolean,
      default: true
    }
  },
  setup(props, { emit }) {
    const internalExpanded = ref(props.expanded)

    watch(() => props.expanded, (newVal) => {
      internalExpanded.value = newVal
    })

    const toggle = () => {
      internalExpanded.value = !internalExpanded.value
      emit('update:expanded', internalExpanded.value)
    }

    return { toggle, internalExpanded }
  }
}
</script>

<style scoped>
/* Using shared styles from components.css */
.collapsible-section {
  width: 100%;
  flex: 0 0 auto;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

/* CollapsibleSection specific override */
.section-header {
  background: var(--color-bg-2);
  padding: var(--spacing-sm) var(--spacing-md);
  flex: 0 0 auto;
  cursor: pointer;
  user-select: none;
}

.section-header:hover {
  background: var(--color-bg-3);
}

/* CollapsibleSection specific animation - matches shared .section-content animation */
.section-content {
  overflow-y: auto;
  flex: 0 0 auto;
  display: flex;
  flex-direction: column;
}

/* When inside a flex container that needs to shrink */
.editor-section {
  min-height: 0;
}
</style>
