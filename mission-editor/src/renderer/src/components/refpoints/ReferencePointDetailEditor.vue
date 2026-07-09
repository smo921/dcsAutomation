<template>
  <EditorPanel title="Reference Point Editor" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content">
      <!-- Basic Settings -->
      <CollapsiblePanel v-model:expanded="expandedSections.basic" title="Basic Settings">
        <div class="editor-section">
          <FormRow>
            <div class="form-group">
              <FormLabel label="Reference Type" />
              <FormInput
                v-model="refPointType"
                disabled
              />
            </div>
          </FormRow>
          <FormRow>
            <div class="form-group">
              <FormLabel label="Name" required />
              <FormInput
                v-model="refPoint.name"
                placeholder="Enter name..."
              />
            </div>
          </FormRow>
        </div>
      </CollapsiblePanel>

      <!-- Type-specific settings -->
      <CollapsiblePanel
        v-model:expanded="expandedSections.coordinates"
        title="Coordinates"
        v-if="showCoordinates"
      >
        <div class="editor-section">
          <FormRow>
            <div class="form-group">
              <FormLabel label="Start X" />
              <FormInput
                v-model="refPoint.startX"
                type="number"
              />
            </div>
            <div class="form-group">
              <FormLabel label="Start Y" />
              <FormInput
                v-model="refPoint.startY"
                type="number"
              />
            </div>
          </FormRow>
          <FormRow>
            <div class="form-group">
              <FormLabel label="End X" />
              <FormInput
                v-model="refPoint.endX"
                type="number"
              />
            </div>
            <div class="form-group">
              <FormLabel label="End Y" />
              <FormInput
                v-model="refPoint.endY"
                type="number"
              />
            </div>
          </FormRow>
        </div>
      </CollapsiblePanel>

      <!-- Notes -->
      <CollapsiblePanel
        v-model:expanded="expandedSections.notes"
        title="Notes"
      >
        <div class="editor-section">
          <div class="info-box">
            <p v-if="refPointType === 'bullseye'">
              <strong>Bullseyes</strong> represent coalition reference points. Coordinates are determined dynamically at runtime from DCS coalition data.
            </p>
            <p v-if="refPointType === 'airbase'">
              <strong>Airbases</strong> reference points for airbase locations. Coordinates are resolved via Airbase.getByName() at runtime.
            </p>
            <p v-if="refPointType === 'zone'">
              <strong>Zones</strong> reference trigger zones defined in the DCS Mission Editor. Enter the exact zone name here to reference it.
            </p>
            <p v-if="refPointType === 'battle_line'">
              <strong>Battle Lines</strong> are linear reference points defined by start and end coordinates. Use these for linear deployment patterns along battle fronts.
            </p>
          </div>
        </div>
      </CollapsiblePanel>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { Button, FormLabel, FormInput, EditorPanel, CollapsiblePanel, FormRow } from '../ui'

const emit = defineEmits(['refpoint-change', 'save', 'cancel'])

const props = defineProps({
  refPoint: {
    type: Object,
    required: true
  }
})

const expandedSections = ref({
  basic: true,
  coordinates: true,
  notes: true
})

// Computed properties based on props
const refPointType = computed(() => props.refPoint.type || '')
const showCoordinates = computed(() => refPointType.value === 'battle_line')

// Emit changes when any modification is made
watch(props.refPoint, (newVal) => {
  emit('refpoint-change', newVal)
}, { deep: true })

const onSave = () => {
  if (!props.refPoint.name) {
    window.dispatchEvent(new CustomEvent('group-status', {
      detail: { message: 'Name is required', type: 'error' }
    }))
    return
  }
  emit('save', props.refPoint)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Shared styles from _components.css: editor-content, editor-section, info-box */
</style>
