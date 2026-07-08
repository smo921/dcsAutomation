<template>
  <svg
    class="icon"
    :class="`icon-${name}`"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <component :is="icons[name]" />
  </svg>
</template>

<script setup>
import { h } from 'vue'

const props = defineProps({
  name: {
    type: String,
    required: true,
    validator: (value) => ['plus', 'minus', 'trash', 'edit', 'x', 'chevronDown', 'chevronUp', 'search', 'settings', 'alert', 'check', 'info'].includes(value)
  },
  size: {
    type: [Number, String],
    default: 24
  }
})

const icons = {
  plus: () => h('path', { d: 'M12 5v14M5 12h14' }),
  minus: () => h('path', { d: 'M5 12h14' }),
  trash: () => h('path', { d: 'M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2' }),
  edit: () => h('path', { d: 'M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7' }, h('path', { d: 'M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z' })),
  x: () => h('path', { d: 'M18 6L6 18M6 6l12 12' }),
  chevronDown: () => h('path', { d: 'M6 9l6 6 6-6' }),
  chevronUp: () => h('path', { d: 'M18 15l-6-6-6 6' }),
  search: () => h('circle', { cx: '11', cy: '11', r: '8' }, h('line', { x1: '21', y1: '21', x2: '16.65', y2: '16.65' })),
  settings: () => h('circle', { cx: '12', cy: '12', r: '3' }, h('path', { d: 'M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z' })),
  alert: () => h('circle', { cx: '12', cy: '12', r: '10' }, h('line', { x1: '12', y1: '8', x2: '12', y2: '12' }), h('line', { x1: '12', y1: '16', x2: '12.01', y2: '16' })),
  check: () => h('polyline', { points: '20 6 9 17 4 12' }),
  info: () => h('circle', { cx: '12', cy: '12', r: '10' }, h('line', { x1: '12', y1: '16', x2: '12', y2: '12' }), h('line', { x1: '12', y1: '8', x2: '12.01', y2: '8' }))
}
</script>

<style scoped>
.icon {
  width: 1em;
  height: 1em;
  stroke-width: 2;
}

/* Size variants */
.icon-plus,
.icon-minus,
.icon-trash,
.icon-edit,
.icon-x,
.icon-alert,
.icon-check,
.icon-info {
  width: 16px;
  height: 16px;
}

.icon-chevron-down,
.icon-chevron-up,
.icon-search,
.icon-settings {
  width: 20px;
  height: 20px;
}
</style>
