<template>
  <div class="form-input-group" :class="{ 'form-input-group-error': hasError }">
    <FormLabel v-if="label" :for="inputId" :required="required" :error="error" />
    <input
      :id="inputId"
      ref="inputRef"
      :type="type"
      v-model="internalValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :min="min"
      :max="max"
      :minlength="minlength"
      :maxlength="maxlength"
      class="form-input"
      :class="{ 'form-input-error': hasError }"
      autocomplete="off"
      @input="handleInput"
      @focus="handleFocus"
      @blur="handleBlur"
    />
    <span v-if="hasError" class="form-input-error">{{ error }}</span>
    <span v-else-if="hint" class="form-input-hint">{{ hint }}</span>
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
  },
  min: {
    type: [Number, String],
    default: null
  },
  max: {
    type: [Number, String],
    default: null
  },
  minlength: {
    type: Number,
    default: null
  },
  maxlength: {
    type: Number,
    default: null
  }
})

const emit = defineEmits(['update:modelValue', 'input', 'focus', 'blur'])

const inputId = ref(`input-${Math.random().toString(36).substring(7)}`)
const internalValue = ref(props.modelValue)
const inputRef = ref(null)
const hasFocus = ref(false)

const hasError = computed(() => {
  return props.error && props.error.length > 0
})

watch(() => props.modelValue, (newVal) => {
  if (newVal !== internalValue.value) {
    internalValue.value = newVal
  }
})

watch(() => internalValue.value, (newVal) => {
  emit('update:modelValue', newVal)
  emit('input', newVal)
})

const handleInput = (e) => {
  internalValue.value = e.target.value
}

const handleFocus = () => {
  hasFocus.value = true
  emit('focus')
}

const handleBlur = () => {
  hasFocus.value = false
  emit('blur')
}

defineExpose({
  focus: () => inputRef.value?.focus(),
  select: () => inputRef.value?.select(),
  element: inputRef
})
</script>

<style scoped>
.form-input-group {
  margin-bottom: var(--spacing-sm);
}

.form-input-group-error .form-label {
  color: var(--color-error);
}

.form-input-error {
  border-color: var(--color-error);
}

.form-input-error:focus {
  outline: none;
  border-color: var(--color-error);
  box-shadow: 0 0 0 2px rgba(163, 19, 19, 0.1);
}

.form-input-hint {
  display: block;
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  margin-top: var(--spacing-xs);
}
</style>
