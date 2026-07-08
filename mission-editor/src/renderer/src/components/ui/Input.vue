<template>
  <div class="input-group" :class="{ 'input-group-error': hasError }">
    <FormLabel v-if="label" :for="inputId" :required="required" :error="error" />
    <input
      :id="inputId"
      ref="inputRef"
      :type="type"
      v-model="internalValue"
      :placeholder="placeholder"
      class="form-input"
      :class="{ 'form-input-error': hasError }"
      :disabled="disabled"
      autocomplete="off"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
    />
    <span v-if="hasError" class="input-error">{{ error }}</span>
    <span v-else-if="hint" class="input-hint">{{ hint }}</span>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { FormLabel } from './index.js'

const props = defineProps({
  modelValue: {
    type: [String, Number, null],
    default: null
  },
  label: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: ''
  },
  type: {
    type: String,
    default: 'text'
  },
  error: {
    type: String,
    default: ''
  },
  disabled: {
    type: Boolean,
    default: false
  },
  required: {
    type: Boolean,
    default: false
  },
  hint: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:modelValue', 'input', 'focus', 'blur'])

const inputId = ref(`input-${Math.random().toString(36).substring(7)}`)
const internalValue = ref(props.modelValue)
const inputRef = ref(null)
const hasFocus = ref(false)

// Compute props
const hasError = computed(() => {
  return props.error && props.error.length > 0
})

// Watch for external changes
watch(() => props.modelValue, (newVal) => {
  if (newVal !== internalValue.value) {
    internalValue.value = newVal
  }
})

watch(() => internalValue.value, (newVal) => {
  emit('update:modelValue', newVal)
  emit('input', newVal)
})

// Focus handler
const handleFocus = () => {
  hasFocus.value = true
  emit('focus')
}

// Blur handler
const handleBlur = () => {
  hasFocus.value = false
  emit('blur')
}

// Input handler
const handleInput = (e) => {
  internalValue.value = e.target.value
}

// Expose methods
defineExpose({
  focus: () => inputRef.value?.focus(),
  select: () => inputRef.value?.select(),
  element: inputRef
})
</script>

<style scoped>
.input-group {
  margin-bottom: var(--spacing-sm);
}

.input-group-error .input-label {
  color: var(--color-error);
}

.form-input {
  width: 100%;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
  transition: border-color var(--transition-fast);
}

.form-input:hover {
  border-color: var(--color-border-focus);
}

.form-input:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 2px rgba(14, 99, 156, 0.1);
}

.form-input:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-input-error {
  border-color: var(--color-error);
}

.input-error {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-error);
  margin-top: var(--spacing-xs);
}

.input-hint {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  margin-top: var(--spacing-xs);
}
</style>
