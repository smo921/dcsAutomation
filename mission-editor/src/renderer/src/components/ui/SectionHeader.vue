<template>
  <div
    class="section-header"
    :class="{ 'section-header-expanded': expanded }"
    @click="toggle"
  >
    <h3 class="section-title">{{ title }}</h3>
    <span class="toggle-icon" :class="{ 'toggle-icon-expanded': expanded }">▼</span>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  title: {
    type: String,
    default: ''
  },
  expanded: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:expanded'])

const internalExpanded = ref(props.expanded)

watch(() => props.expanded, (newVal) => {
  internalExpanded.value = newVal
})

const toggle = () => {
  internalExpanded.value = !internalExpanded.value
  emit('update:expanded', internalExpanded.value)
}
</script>

<style scoped>
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-xs) var(--spacing-sm);
  cursor: pointer;
  user-select: none;
  transition: background var(--transition-fast);
}

.section-header:hover {
  background: var(--color-bg-3);
}

.section-title {
  font-size: var(--font-size-sm);
  color: var(--color-text-0);
  margin: 0;
  font-weight: var(--font-weight-medium);
}

.toggle-icon {
  font-size: var(--font-size-xxs);
  color: var(--color-text-1);
  transition: transform var(--transition-fast);
}

.toggle-icon-expanded {
  transform: rotate(180deg);
}
</style>
