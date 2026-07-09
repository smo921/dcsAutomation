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
/* CollapsibleSection specific overrides */
.collapsible-section {
  flex: 0 0 auto;
  min-height: 0;
}

.section-header {
  background: var(--color-bg-2);
  padding: var(--spacing-sm) var(--spacing-md);
  flex: 0 0 auto;
}

/* CollapsibleSection specific animation */
.section-content {
  overflow-y: auto;
  flex: 0 0 auto;
}

/* Editor section override */
.editor-section {
  min-height: 0;
}
</style>
