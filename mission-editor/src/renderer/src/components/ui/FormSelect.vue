<template>
  <div class="form-select-group" :class="{ 'form-select-group-error': hasError }">
    <FormLabel v-if="label" :for="selectId" :required="required" :error="error" />
    <select
      :id="selectId"
      ref="selectRef"
      v-model="internalValue"
      :disabled="disabled"
      class="form-select"
      :class="{ 'form-select-error': hasError }"
      @change="handleChange"
      @focus="handleFocus"
      @blur="handleBlur"
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
    <span v-if="hasError" class="form-select-error">{{ error }}</span>
    <span v-else-if="hint" class="form-select-hint">{{ hint }}</span>
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

watch(() => props.modelValue, (newVal) => {
  if (newVal !== internalValue.value) {
    internalValue.value = newVal
  }
})

watch(() => internalValue.value, (newVal) => {
  emit('update:modelValue', newVal)
  emit('change', newVal)
})

const handleChange = (e) => {
  internalValue.value = e.target.value
}

const handleFocus = () => {
  emit('focus')
}

const handleBlur = () => {
  emit('blur')
}

defineExpose({
  focus: () => selectRef.value?.focus(),
  element: selectRef
})
</script>

<style scoped>
.form-select-group {
  margin-bottom: var(--spacing-sm);
}

.form-select-group-error .form-label {
  color: var(--color-error);
}

.form-select-error {
  border-color: var(--color-error);
}

.form-select-error:focus {
  outline: none;
  border-color: var(--color-error);
  box-shadow: 0 0 0 2px rgba(163, 19, 19, 0.1);
}

.form-select-hint {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  margin-top: var(--spacing-xs);
}
</style>
