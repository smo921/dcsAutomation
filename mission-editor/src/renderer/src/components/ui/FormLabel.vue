<template>
  <label
    :class="['form-label', 'input-label', 'select-label', { 'form-label-required': required, 'form-label-error': hasError }]"
    :for="inputId"
  >
    <span class="form-label-text">{{ label }}</span>
    <span v-if="required" class="input-required select-required">*</span>
  </label>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  label: {
    type: String,
    default: ''
  },
  for: {
    type: String,
    default: ''
  },
  required: {
    type: Boolean,
    default: false
  },
  error: {
    type: String,
    default: ''
  }
})

const inputId = ref(props.for || `input-${Math.random().toString(36).substring(7)}`)

const hasError = props.error && props.error.length > 0
</script>

<style scoped>
.form-label {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-3);
  margin-bottom: var(--spacing-xs);
  font-weight: var(--font-weight-medium);
}

.form-label-text {
  margin-right: var(--spacing-xxs);
}

.form-label-required-indicator {
  color: var(--color-error);
}

.form-label-error {
  color: var(--color-error);
}
</style>
