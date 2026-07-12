<template>
  <div class="form-row">
    <slot />
  </div>
</template>

<script setup>
// FormRow - Grid-based form row for two-column layouts
// Use with form-group children containing label+input pairs
// Each form-group takes one column, pairs wrap to additional rows
</script>

<style scoped>
.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-sm);
}

/* Ensure form-group children are direct grid items (both raw div and FormGroup component) */
.form-row > .form-group,
.form-row > .form-group.vue {
  display: flex;
  flex-direction: column;
}
</style>
