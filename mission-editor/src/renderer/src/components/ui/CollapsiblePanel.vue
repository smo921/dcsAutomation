<template>
  <div
    class="collapsible-panel"
    :class="{ 'is-expanded': expanded, 'is-collapsed': !expanded }"
  >
    <SectionHeader
      :title="title"
      :expanded="expanded"
      @update:expanded="$emit('update:expanded', $event)"
    >
      <template v-if="icon" #icon>
        <span class="panel-icon">{{ icon }}</span>
      </template>
    </SectionHeader>

    <div v-if="expanded" class="panel-content">
      <slot></slot>
    </div>

    <div v-else-if="$slots.collapsedContent" class="panel-collapsed-content">
      <slot name="collapsedContent"></slot>
    </div>
  </div>
</template>

<script setup>
import SectionHeader from './SectionHeader.vue'

const props = defineProps({
  title: {
    type: String,
    default: ''
  },
  icon: {
    type: String,
    default: ''
  },
  expanded: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['update:expanded'])
</script>

<style scoped>
/* Uses shared classes from _components.css */
</style>
