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
.collapsible-section {
  width: 100%;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  cursor: pointer;
  user-select: none;
  transition: background 0.2s;
}

.section-header:hover {
  background: #303030;
}

.section-title {
  font-size: 12px;
  color: #d4d4d4;
  margin: 0;
  font-weight: 500;
}

.toggle-icon {
  font-size: 10px;
  color: #888;
  transition: transform 0.2s;
}

.toggle-icon.expanded {
  transform: rotate(180deg);
}

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
