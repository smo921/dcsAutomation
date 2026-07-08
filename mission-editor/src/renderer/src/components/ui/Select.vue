<template>
  <div class="select-group" :class="{ 'select-group-error': hasError }">
    <FormLabel v-if="label" :for="selectId" :required="required" :error="error" />
    <select
      :id="selectId"
      ref="selectRef"
      v-model="internalValue"
      class="form-select"
      :class="{ 'form-select-error': hasError }"
      :disabled="disabled"
      @change="$emit('update:modelValue', $event.target.value)"
      @focus="$emit('focus')"
      @blur="$emit('blur')"
    >
      <option v-if="placeholder" value="" disabled>{{ placeholder }}</option>
      <option
        v-for="option in options"
        :key="getOptionValue(option)"
        :value="getOptionValue(option)"
      >
        {{ getOptionLabel(option) }}
      </option>
    </select>
    <span v-if="hasError" class="select-error">{{ error }}</span>
    <span v-else-if="hint" class="select-hint">{{ hint }}</span>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { FormLabel } from './index.js'

const props = defineProps({
  modelValue: {
    type: [String, Number, Boolean, null],
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
  options: {
    type: Array,
    default: () => []
  },
  valueKey: {
    type: String,
    default: 'value'
  },
  labelKey: {
    type: String,
    default: 'label'
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

const emit = defineEmits(['update:modelValue', 'change', 'focus', 'blur'])

const selectId = ref(`select-${Math.random().toString(36).substring(7)}`)
const internalValue = ref(props.modelValue)
const selectRef = ref(null)

// Computed
const hasError = computed(() => {
  return props.error && props.error.length > 0
})

const getOptionValue = (option) => {
  if (typeof option === 'object' && option !== null) {
    return option[props.valueKey]
  }
  return option
}

const getOptionLabel = (option) => {
  if (typeof option === 'object' && option !== null) {
    return option[props.labelKey]
  }
  return option
}

// Watchers
watch(() => props.modelValue, (newVal) => {
  if (newVal !== internalValue.value) {
    internalValue.value = newVal
  }
})

watch(() => internalValue.value, (newVal) => {
  emit('update:modelValue', newVal)
  emit('change', newVal)
})

// Expose methods
defineExpose({
  focus: () => selectRef.value?.focus(),
  element: selectRef
})
</script>

<style scoped>
.select-group {
  margin-bottom: var(--spacing-sm);
}

.select-group-error .select-label {
  color: var(--color-error);
}

.form-select {
  width: 100%;
  background: var(--color-bg-2);
  border: 1px solid var(--color-border);
  color: var(--color-text-4);
  padding: var(--spacing-xs);
  border-radius: var(--spacing-xxs);
  transition: border-color var(--transition-fast);
  cursor: pointer;
}

.form-select:hover {
  border-color: var(--color-border-focus);
}

.form-select:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 2px rgba(14, 99, 156, 0.1);
}

.form-select:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.form-select-error {
  border-color: var(--color-error);
}

.select-error {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-error);
  margin-top: var(--spacing-xs);
}

.select-hint {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  margin-top: var(--spacing-xs);
}
</style>
