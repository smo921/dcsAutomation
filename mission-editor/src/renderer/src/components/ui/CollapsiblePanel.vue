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
/* Collapsible Panel - uses SectionHeader for header styling */

.collapsible-panel {
  width: 100%;
  display: flex;
  flex-direction: column;
  background: var(--color-bg-1);
  border-radius: var(--spacing-xxs);
  overflow: hidden;
  border: 1px solid var(--color-border);
}

.collapsible-panel.is-expanded .section-header {
  border-bottom: 1px solid var(--color-border);
}

/* Panel Content */
.panel-content {
  padding: var(--spacing-md);
  overflow-y: auto;
  flex: 0 0 auto;
}

/* Collapsed Content Slot */
.panel-collapsed-content {
  padding: var(--spacing-sm) var(--spacing-md);
  color: var(--color-text-2);
  font-size: var(--font-size-xxs);
}

/* Panel Icon */
.panel-icon {
  margin-right: var(--spacing-sm);
  font-size: var(--font-size-lg);
  line-height: 1;
}
</style>
