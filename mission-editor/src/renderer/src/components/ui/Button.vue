<template>
  <button
    :class="['btn', `btn-${variant}`, `btn-${size}`, { 'btn-icon-only': iconOnly, 'btn-block': block }]"
    :disabled="disabled"
    :type="type"
    v-bind="$attrs"
  >
    <span v-if="$slots.icon" class="btn-icon">
      <slot name="icon" />
    </span>
    <slot />
  </button>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (value) => ['primary', 'danger', 'secondary', 'ghost'].includes(value)
  },
  size: {
    type: String,
    default: 'md',
    validator: (value) => ['sm', 'md', 'lg'].includes(value)
  },
  type: {
    type: String,
    default: 'button',
    validator: (value) => ['button', 'submit', 'reset'].includes(value)
  },
  disabled: {
    type: Boolean,
    default: false
  },
  block: {
    type: Boolean,
    default: false
  },
  iconOnly: {
    type: Boolean,
    default: false
  }
})

// Compute the CSS class prefix based on variant
const getVariantStyles = computed(() => {
  const styles = {
    primary: {
      background: 'var(--color-primary)',
      color: 'white',
      hover: 'var(--color-primary-hover)',
      focus: 'var(--color-border-focus)'
    },
    danger: {
      background: 'var(--color-error)',
      color: 'white',
      hover: 'var(--color-error-hover)',
      focus: 'var(--color-border-focus)'
    },
    secondary: {
      background: 'var(--color-bg-2)',
      color: 'var(--color-text-0)',
      border: 'var(--color-border)',
      hover: 'var(--color-bg-3)',
      focus: 'var(--color-border-focus)'
    },
    ghost: {
      background: 'transparent',
      color: 'var(--color-text-0)',
      hover: 'var(--color-bg-3)',
      focus: 'var(--color-border-focus)'
    }
  }
  return styles[props.variant]
})
</script>

<style>
/* Shared button styles from _buttons.css */
</style>
