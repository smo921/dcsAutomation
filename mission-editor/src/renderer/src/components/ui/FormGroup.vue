<template>
  <div class="form-group" :class="{ 'form-group-error': hasError }">
    <slot />
    <span v-if="hasError" class="form-group-error-message">{{ error }}</span>
    <span v-else-if="hint" class="form-group-hint">{{ hint }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  error: {
    type: String,
    default: ''
  },
  hint: {
    type: String,
    default: ''
  }
})

const hasError = computed(() => {
  return props.error && props.error.length > 0
})
</script>

<style scoped>
.form-group {
  margin-bottom: var(--spacing-sm);
}

.form-group-error-message {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-error);
  margin-top: var(--spacing-xs);
}

.form-group-hint {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  margin-top: var(--spacing-xs);
}
</style>
