# Drag-to-Edit Implementation Plan

## Implementation Status

**Phase 1: Basic Route Point Dragging** - ✅ COMPLETED (2026-07-17)
- Added drag state tracking (isDragging, draggingPointIndex, dragStartPos)
- Made route point circles draggable with mousedown handler
- Implemented screen-to-world conversion and drag handlers
- Added route-point-move emit event
- Added visual feedback (draggable cursor, opacity change, pulse animation, coordinate tooltip)
- Integrated with UnitEditor via handleRoutePointMove handler

**Phase 2: Placement Origin Dragging** - ⏳ PENDING
**Phase 3: UnitEditor Integration** - ✅ COMPLETED (basic integration done)
**Phase 4: Visual Feedback** - ✅ COMPLETED (basic feedback done)

---

## Overview

Add interactive drag-to-edit functionality to the RoutePreviewCanvas component, allowing users to modify route points and placement by dragging. The placement mode (BEARING_DISTANCE, COORDINATE, etc.) should NOT change - instead, the appropriate values for that mode should be calculated and updated.

---

## Architecture

### Data Flow

```
RoutePreviewCanvas (drag event)
    ↓
emit('point-move', { pointIndex, newX, newY })
    ↓
UnitEditor (receives event)
    ↓
Calculate new values based on placement mode
    ↓
Update unit.placement or unit.route
    ↓
emit('unit-change', updatedUnit)
```

---

## Implementation Phases

### Phase 1: Draggable Route Points (x/y offset modes)

**Target:** Route points with `type: 'turn_point'` or `type: 'heading'` that have explicit x/y coordinates.

#### Steps:

1. **Add draggable attribute to route point circles**
   ```vue
   <circle
     r="10"
     :class="['route-point-marker', { draggable: isPointDraggable(point) }]"
     @mousedown="handlePointDragStart($event, index)"
   />
   ```

2. **Add drag state tracking**
   ```js
   const isDragging = ref(false)
   const draggingPointIndex = ref(-1)
   const dragStartPos = ref({ x: 0, y: 0 })
   ```

3. **Implement drag handlers**
   - `handlePointDragStart(event, index)` - Start dragging a point
   - `handleDragMove(event)` - Update point position during drag
   - `handleDragEnd(event)` - Finalize position and emit changes

4. **Emit changes to parent**
   ```js
   emit('route-point-move', {
     index: draggingPointIndex.value,
     x: newRawX,
     y: newRawY
   })
   ```

#### Placement Mode Handling:

| Placement Mode | Behavior |
|----------------|----------|
| `COORDINATE` | Update route point x/y directly |
| `BEARING_DISTANCE` | Update route point x/y (offset from reference) |
| `AIRBASE_RAMP` | Update route point x/y (offset from airbase) |
| `ZONE_CENTER` | Update route point x/y (offset from zone) |

**Key:** Route points are ALWAYS stored as x/y offsets. The placement mode determines what the reference point is, not how route points are stored.

---

### Phase 2: Draggable Placement Origin

**Target:** Moving the entire route by dragging the start/origin point.

#### Steps:

1. **Make origin marker draggable**
   ```vue
   <g
     v-if="showPlacementOrigin"
     class="placement-origin draggable"
     @mousedown="handleOriginDragStart"
   >
   ```

2. **Calculate delta on drag**
   ```js
   const delta = {
     x: worldPos.x - dragStartPos.x,
     y: worldPos.y - dragStartPos.y
   }
   ```

3. **Update placement based on mode**

#### Placement Mode Calculations:

**COORDINATE Mode:**
```js
placement.x += delta.x
placement.y += delta.y
// Also shift all route points
route.forEach(p => {
  p.x += delta.x
  p.y += delta.y
})
```

**BEARING_DISTANCE Mode:**
```js
// Calculate new bearing and distance from reference point
const refPoint = getReferencePoint(placement.reference, placement.referenceName)
const dx = placement.x - refPoint.x
const dy = placement.y - refPoint.y

placement.bearing = (Math.atan2(dx, dy) * 180 / Math.PI + 360) % 360
placement.distance = Math.sqrt(dx*dx + dy*dy) / 1852  // meters to NM
```

**AIRBASE_RAMP Mode:**
```js
// Update parking slot offset or switch to COORDINATE mode
// Option: Show dialog asking user if they want to change placement mode
```

**ZONE_CENTER Mode:**
```js
// Similar to BEARING_DISTANCE - calculate offset from zone center
```

---

### Phase 3: UnitEditor Integration

#### Steps:

1. **Add event listener for route-point-move**
   ```vue
   <RoutePreviewCanvas
     @route-point-move="handleRoutePointMove"
     @placement-move="handlePlacementMove"
   />
   ```

2. **Implement handlers**
   ```js
   const handleRoutePointMove = ({ index, x, y }) => {
     currentUnit.value.route[index].x = x
     currentUnit.value.route[index].y = y
     emitUnitChange()
   }

   const handlePlacementMove = ({ placement, route }) => {
     currentUnit.value.placement = placement
     if (route) {
       currentUnit.value.route = route
     }
     emitUnitChange()
   }
   ```

3. **Add undo support (optional)**
   ```js
   const undoStack = ref([])
   const pushToUndo = () => {
     undoStack.value.push(JSON.parse(JSON.stringify(currentUnit.value)))
     if (undoStack.value.length > 10) undoStack.value.shift()
   }
   ```

---

### Phase 4: Visual Feedback

#### During Drag:

1. **Show ghost/drag preview**
   ```vue
   <circle
     v-if="isDragging"
     :cx="dragPreview.x"
     :cy="dragPreview.y"
     class="drag-preview"
   />
   ```

2. **Highlight affected elements**
   - Selected point: brighter color, thicker stroke
   - Connection lines: dashed animation

3. **Show coordinate tooltip**
   ```vue
   <text
     v-if="isDragging"
     :x="dragPos.x"
     :y="dragPos.y - 20"
     class="drag-tooltip"
   >
     {{ formatCoords(dragPos) }}
   </text>
   ```

#### CSS Classes:
```css
.route-point.draggable {
  cursor: move;
}

.route-point.dragging {
  opacity: 0.5;
}

.drag-preview {
  fill: var(--color-primary);
  opacity: 0.3;
  pointer-events: none;
}

.drag-tooltip {
  fill: var(--color-text-1);
  font-size: 10px;
  background: var(--color-bg-2);
  padding: 2px 4px;
  border-radius: 2px;
}
```

---

## File Changes

### New/Modified Components

| File | Changes |
|------|---------|
| `RoutePreviewCanvas.vue` | Add drag handlers, emit events, visual feedback |
| `UnitEditor.vue` | Add event listeners, update handlers |
| `RouteEditor.vue` | Pass through events from RoutePreviewCanvas |

### New Composables (Optional)

```js
// composables/useRouteDrag.js
export function useRouteDrag(props, emit) {
  const isDragging = ref(false)
  const draggingPointIndex = ref(-1)
  
  const handleDragStart = (event, index) => { ... }
  const handleDragMove = (event) => { ... }
  const handleDragEnd = (event) => { ... }
  
  return {
    isDragging,
    draggingPointIndex,
    handleDragStart,
    handleDragMove,
    handleDragEnd
  }
}
```

---

## Coordinate Conversion Utilities

### Screen to World
```js
const screenToWorld = (screenX, screenY, svgRect, panX, panY, zoom) => {
  return {
    x: (screenX - svgRect.left - panX) / zoom,
    y: (screenY - svgRect.top - panY) / zoom
  }
}
```

### World to Screen
```js
const worldToScreen = (worldX, worldY, svgRect, panX, panY, zoom) => {
  return {
    x: worldX * zoom + panX + svgRect.left,
    y: worldY * zoom + panY + svgRect.top
  }
}
```

### Bearing/Distance Calculations
```js
// Calculate bearing from two points (in degrees)
const calculateBearing = (from, to) => {
  const dx = to.x - from.x
  const dy = to.y - from.y
  return (Math.atan2(dx, dy) * 180 / Math.PI + 360) % 360
}

// Calculate distance between two points (in nautical miles)
const calculateDistance = (from, to) => {
  const dx = to.x - from.x
  const dy = to.y - from.y
  return Math.sqrt(dx*dx + dy*dy) / 1852  // meters to NM
}

// Calculate position from bearing and distance
const calculatePosition = (from, bearing, distanceNm) => {
  const distanceM = distanceNm * 1852
  const bearingRad = bearing * Math.PI / 180
  return {
    x: from.x + Math.sin(bearingRad) * distanceM,
    y: from.y + Math.cos(bearingRad) * distanceM
  }
}
```

---

## Testing Checklist

### Route Point Dragging
- [ ] Can drag turn_point waypoints
- [ ] Can drag heading waypoints
- [ ] Cannot drag orbit waypoints (no x/y)
- [ ] Cannot drag landing waypoints (airbase-based)
- [ ] Connection lines update during drag
- [ ] Coordinates display updates during drag

### Placement Origin Dragging
- [ ] COORDINATE mode: x/y values update
- [ ] BEARING_DISTANCE mode: bearing/distance values update
- [ ] AIRBASE_RAMP mode: prompts user or updates offset
- [ ] All route points shift with origin

### Visual Feedback
- [ ] Cursor changes to move cursor on hover
- [ ] Dragged point becomes semi-transparent
- [ ] Ghost preview shows drop location
- [ ] Coordinate tooltip follows cursor

### Edge Cases
- [ ] Dragging outside canvas bounds
- [ ] Multiple rapid drags
- [ ] Undo/redo functionality
- [ ] Save before drag completes

---

## Implementation Order

1. **Phase 1** - Basic route point dragging (x/y modes)
2. **Phase 4** - Visual feedback (cursor, highlights, tooltips)
3. **Phase 2** - Placement origin dragging with mode calculations
4. **Phase 3** - UnitEditor integration and undo support

---

## Notes

- Route points are stored as x/y offsets regardless of placement mode
- Placement mode determines the REFERENCE point, not the storage format
- BEARING_DISTANCE calculates bearing/distance FROM reference TO placement origin
- Orbit and Landing type points cannot be dragged (no x/y coordinates)
- Consider adding a "lock" toggle to prevent accidental drags
