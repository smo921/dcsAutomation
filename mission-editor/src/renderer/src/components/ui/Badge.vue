<template>
  <span :class="['badge', `badge-${variant}`, `badge-${size}`]">
    <span v-if="$slots.icon" class="badge-icon">
      <slot name="icon" />
    </span>
    <slot />
  </span>
</template>

<script setup>
const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'success', 'error', 'info', 'warning'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  }
})
</script>

<style scoped>
/* Uses shared classes from _components.css: badge, badge-primary, badge-success, badge-error, badge-info, badge-warning, badge-sm, badge-lg, badge-icon-only */
</style>
