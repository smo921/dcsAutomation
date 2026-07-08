<template>
  <div class="form-row">
    <slot />
  </div>
</template>

<script setup>
// FormRow - Grid-based form row for two-column layouts
// Usage:
// <FormRow>
//   <FormLabel label="Field 1" />
//   <FormInput v-model="field1" />
//   <FormLabel label="Field 2" />
//   <FormInput v-model="field2" />
// </FormRow>
</script>

<style scoped>
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-sm);
}
</style>
