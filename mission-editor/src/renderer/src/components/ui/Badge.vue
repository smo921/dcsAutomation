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
.badge {
  display: inline-flex;
  align-items: center;
  padding: var(--spacing-xxs) var(--spacing-sm);
  border-radius: var(--spacing-xxs);
  font-size: var(--font-size-xxs);
  font-weight: var(--font-weight-medium);
  user-select: none;
}

/* Variants */
.badge-primary {
  background: var(--color-bg-2);
  color: var(--color-text-1);
}

.badge-success {
  background: var(--color-success);
  color: white;
}

.badge-error {
  background: var(--color-error);
  color: white;
}

.badge-info {
  background: var(--color-primary);
  color: white;
}

.badge-warning {
  background: var(--color-warning);
  color: white;
}

/* Sizes */
.badge-sm {
  padding: var(--spacing-xxs) var(--spacing-xs);
  font-size: var(--font-size-xxs);
}

.badge-lg {
  padding: var(--spacing-xs) var(--spacing-sm);
  font-size: var(--font-size-xxs);
}

/* Icon spacing */
.badge:not(.badge-icon-only) .badge-icon {
  margin-right: var(--spacing-xs);
}

.badge-icon-only .badge-icon {
  margin: 0;
}
</style>
