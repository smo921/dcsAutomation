<template>
  <div class="empty-state">
    <slot />
  </div>
</template>

<script setup>
// EmptyState - Reusable empty state component
// Usage:
// <EmptyState>
//   <p>No items found.</p>
// </EmptyState>
</script>

<style scoped>
.empty-state {
  padding: var(--spacing-lg);
  text-align: center;
  color: var(--color-text-1);
  font-size: var(--font-size-sm);
}

.empty-state p {
  margin-bottom: var(--spacing-xs);
}

.empty-state .note {
  font-size: var(--font-size-xxs);
  color: var(--color-text-2);
  font-style: italic;
  margin-top: var(--spacing-xs);
}
</style>
