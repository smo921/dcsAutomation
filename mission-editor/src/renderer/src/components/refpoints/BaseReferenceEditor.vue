<template>
  <div class="refpoint-editor base-reference-editor">
    <div class="editor-header">
      <h3>{{ title }}</h3>
      <Button v-if="showAddButton" @click="showAddModal = true" variant="primary">
        <span>+</span> {{ addButtonText }}
      </Button>
    </div>

    <EmptyState v-if="items.length === 0">
      <p>{{ emptyStateText }}</p>
      <p v-if="emptyStateNote" class="note">{{ emptyStateNote }}</p>
    </EmptyState>

    <div v-for="(item, index) in items" :key="index" class="item-row">
      <div class="item-header">
        <FormInput
          v-model="item.name"
          :placeholder="itemPlaceholder || 'Name'"
        />
        <Button variant="danger" size="sm" @click="removeItem(index)">
          <span class="btn-remove-icon">✕</span>
        </Button>
      </div>

      <!-- Custom fields rendered via slot if provided -->
      <div v-if="$slots.customFields" class="coordinate-inputs">
        <slot name="customFields" :item="item" :index="index" />
      </div>
    </div>

    <Modal v-model:open="showAddModal" :title="addModalTitle" close-text="Cancel">
      <template #content>
        <div class="input-group">
          <FormLabel label="Name" required />
          <FormInput
            v-model="newItemName"
            :placeholder="namePlaceholder"
          />
        </div>

        <!-- Custom fields for add modal rendered via slot -->
        <div v-if="$slots.addModalFields" class="coordinate-inputs">
          <slot name="addModalFields" />
        </div>
      </template>
      <template #actions>
        <Button @click="handleAddItem" variant="primary">Add</Button>
      </template>
    </Modal>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { FormInput, FormLabel, Modal, Button, EmptyState } from '../ui'

const props = defineProps({
  title: { type: String, required: true },
  addButtonText: { type: String, default: 'Add' },
  emptyStateText: { type: String, default: 'No items configured.' },
  emptyStateNote: { type: String, default: '' },
  itemPlaceholder: { type: String, default: 'Name' },
  addModalTitle: { type: String, default: 'Add Item' },
  namePlaceholder: { type: String, default: 'Enter name...' },
  showAddButton: { type: Boolean, default: true }
})

const emit = defineEmits(['update', 'add'])

const items = defineModel('items', { type: Array, default: () => [] })
const newItemName = ref('')
const showAddModal = ref(false)

// Relay updates to parent
const emitUpdate = () => {
  emit('update')
}

// Remove item from list
const removeItem = (index) => {
  items.value.splice(index, 1)
  emitUpdate()
}

// Handle add item - delegates to parent via event
const handleAddItem = () => {
  emit('add', newItemName.value)
  newItemName.value = ''
  showAddModal.value = false
  emitUpdate()
}
</script>

<style scoped>
/* Uses shared .refpoint-editor class from components.css */
</style>
