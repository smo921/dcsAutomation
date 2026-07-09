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
/* Uses shared classes from _components.css: section-header, section-title, toggle-icon, toggle-icon-expanded */
</style>
