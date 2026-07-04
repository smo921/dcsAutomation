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
import { ref, watch, defineComponent } from 'vue'

export default defineComponent({
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
})
</script>

<style scoped>
/* Using shared styles from components.css */
.collapsible-section {
  width: 100%;
}

/* Override the hover background since shared style uses CSS variable */
.section-header:hover {
  background: #303030;
}

/* Animation override for nested scoped styles */
.section-content {
  overflow: hidden;
  animation: slideDown 0.3s ease-out;
}

@keyframes slideDown {
  from {
    max-height: 0;
    opacity: 0;
  }
  to {
    max-height: 2000px;
    opacity: 1;
  }
}
</style>
