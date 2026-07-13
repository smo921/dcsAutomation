<template>
  <EditorPanel :title="`Route Template: ${localTemplateName}`" variant="primary">
    <template #toolbar>
      <Button @click="onSave" variant="primary">Save</Button>
      <Button @click="onCancel" variant="secondary">Cancel</Button>
    </template>

    <div class="editor-content">
      <!-- Template name input -->
      <div class="editor-section">
        <FormRow>
          <FormGroup>
            <FormLabel label="Template Name" />
            <FormInput v-model="localTemplateName" placeholder="Enter route template name..." />
          </FormGroup>
        </FormRow>
      </div>

      <!-- Route Editor - reusable component for route management -->
      <div class="editor-section">
        <RouteEditor
          :route="route"
          :airbases="airbases"
          @update:route="route = $event"
        />
      </div>
    </div>
  </EditorPanel>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { FormInput, FormRow, FormLabel, EditorPanel, Button } from '../ui'
import FormGroup from '../ui/FormGroup.vue'
import RouteEditor from './RouteEditor.vue'

const emit = defineEmits(['save', 'cancel', 'update:route', 'update:templateName'])

const props = defineProps({
  route: {
    type: Array,
    default: () => []
  },
  airbases: {
    type: Array,
    default: () => []
  },
  templateName: {
    type: String,
    default: 'Unnamed Route Template'
  }
})

// Local ref for template name (since prop can't be directly modified)
const localTemplateName = ref(props.templateName)

// Emit update when template name changes
watch(localTemplateName, (newVal) => {
  emit('update:templateName', newVal)
})

const onSave = () => {
  emit('save', props.route)
}

const onCancel = () => {
  emit('cancel')
}
</script>

<style scoped>
/* Uses shared classes from _components.css: editor-content, editor-section */
/* Route template editor - extends RouteEditor component */
</style>
