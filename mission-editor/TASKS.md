# DCS Mission Editor - Task List

This file tracks the implementation tasks for the DCS Mission Editor MVP.

## Status Legend
- **[ ]** Pending
- **[x]** Completed
- **[i]** In Progress

---

## Completed Tasks (From Previous Sessions)

### Phase 0: Project Setup
- [x] Initialize Electron project with Vite + Vue 3
- [x] Create main Electron process (index.js, preload.js)
- [x] Configure electron-vite build system
- [x] Set up Vue component structure
- [x] Create README.md documentation
- [x] Refactor project structure to match electron-vite recommendations (2026-07-02)

### Phase 1: Core Infrastructure
- [x] Create Reference Point Manager (main/refpoints/manager.js)
- [x] Create Reference Point Helpers (main/refpoints/helpers.js)
- [x] Create Template Manager (main/templates/manager.js)
- [x] Create Coordinate Utilities (main/utils/coords.js)
- [x] Create Waypoint Service (main/waypoints/service.js)
- [x] Create Configuration Generator (main/config/generator.js)

### Phase 2: Vue UI Components
- [x] Build Vue renderer window with basic layout
- [x] Build Reference Point Editors (Bullseye, Airbase, Zone, Battle Line)
- [x] Build Group Editor component
- [x] Build Waypoint Editor component
- [x] Build Template Library component

### Phase 2b: UI Layout Refactor (Completed 2026-07-03)
- [x] Create CollapsibleSection component for sidebar
- [x] Implement tab-based navigation (Groups/Waypoints)
- [x] Add resizeable sidebar with horizontal resizing
- [x] Add resizeable list area with vertical resizing
- [x] Create reusable useResize composable for consistent behavior
- [x] Add content-divider between tabs and list area
- [x] Add proper styling with flexbox layout

### Phase 3: State Management
- [x] Create Pinia stores (refpoints, templates)

### Phase 3: Sidebar Layout Refactor (Completed 2026-07-06)
- [x] Update CollapsibleSection to properly size content with flex: 0 0 auto
- [x] Add min-height: 0 to CollapsibleSection for proper flex behavior
- [x] Update App.vue sidebar to use flex: 1 and overflow-y: auto
- [x] Add custom scrollbar styles for sidebar
- [x] Remove min-height: 200px from ReferencePointManager refpoint-content
- [x] Fix spacing between collapsible sections
- [x] Add reference type filtering for reference name dropdowns
- [x] Standardize delete button styling across all components
- [x] Add tabbed layout to Groups, Templates, and Reference Points
- [x] Add delete functionality for Waypoint Templates
- [x] Refactor duplicated CSS into shared styles in components.css
- [x] Add .flex-fill helper class for flex containers

### Phase 4: Reference Point Configuration (Completed 2026-07-02)
- [x] Bullseye editor UI (fully connected with add/remove, auto-save)
- [x] Airbase manual entry (name + coordinates + runway heading)
- [x] Trigger zone editor (name input, auto-save on changes)
- [x] Battle line editor (name + start/end coordinates, auto-save)
- [x] Dynamic component binding fix for proper rendering

### Phase 4: Templates
- [x] Create default template files (air, ground, support)

### Phase 5: Templates & Waypoint Templates
- [x] Create TemplateLibrary component with search
- [x] Create WaypointTemplateLibrary component
- [x] Add template application to groups
- [x] Add template creation/editing in-app
- [x] Add dynamic template management (add/remove)

### Phase 5: IPC & Export
- [x] Implement JSON export functionality
- [x] Implement Lua code export
- [x] Create validation layer

---

## Remaining Tasks

### Phase 6: Visualization
- [ ] Add map preview component
- [ ] Coordinate conversion utilities (Vue-side)
- [ ] Visual preview of generated route

### Phase 7: Advanced Features
- [x] Multiple group management
- [x] Template association to groups

### Phase 8: Placement Mode Refactor (2026-07-02) - COMPLETED
- [x] Decouple placement mode from reference type - make them independent choices
  - Previously: Each position type bundled both mode (bearing+distance) and origin (bullseye/airbase)
  - Now: User selects placement mode first, then reference type separately
- [x] Update GroupEditor to support decoupled approach
- [x] Add support for waypoints in GroupEditor (group name + waypoint number)
- [x] Update template loading to work with decoupled placement config
- [x] Ensure distance inputs use NM (nautical miles) as per Lua code conventions
- [x] Update Lua unit_management.lua to support refType and referenceName

### Phase 9: Group Management (Completed 2026-07-03)
- [x] Replace GroupEditor with GroupManager component
- [x] Add template association to groups
- [x] Add GroupManager with group list and editor panel
- [x] Implement resizeable list area between group list and editor
- [x] Add waypoint template application support
- [x] Support for creating groups from templates

### Phase 9: Zone Randomization & Waypoint Anchoring
- [x] Zone Randomization support in Lua (ZONE_RANDOM strategy)
- [x] Waypoint anchoring support in Lua (groupName + waypoint)

### Phase 10: .miz Integration
- [ ] .miz file opening (zip extraction)
- [ ] Lua parsing and extraction
- [ ] Configuration injection
- [ ] File repackaging
- [ ] Backup functionality

### Phase 11: Testing & Validation
- [ ] Test with existing unit_management.lua
- [ ] Integration testing
- [ ] Documentation updates

---

## Quick Reference

### Development Commands
```bash
cd mission-editor
npm run dev     # Start dev server
npm run build   # Build production
npm run preview # Run built app
```

### Project Structure
```
mission-editor/
├── electron.vite.config.js    # Build configuration
├── config/                    # Templates and configs
│   └── templates/             # JSON template files
├── src/
│   ├── main/
│   │   └── index.js           # Electron main process
│   ├── preload/
│   │   └── preload.js         # Preload script
│   └── renderer/
│       ├── index.html
│       ├── vite.config.js
│       ├── public/
│       └── src/
│           ├── App.vue
│           ├── main.js
│           ├── stores/
│           │   ├── refpoints.js
│           │   └── templates.js
│           └── components/
│               ├── editor/
│               │   ├── GroupEditor.vue
│               │   └── WaypointEditor.vue
│               ├── refpoints/
│               │   ├── AirbaseEditor.vue
│               │   ├── BattleLineEditor.vue
│               │   ├── BullseyeEditor.vue
│               │   ├── ReferencePointManager.vue
│               │   └── ZoneEditor.vue
│               └── templates/
│                   └── TemplateLibrary.vue
└── out/                       # Build output (generated)
```

### Reference Point Types
- **bullseye** - Global reference (X/Y coordinates)
- **airbase** - Named airbase (resolved at runtime via Airbase.getByName())
- **zone** - Trigger zone from DCS Mission Editor
- **battle_line** - Custom line segment
- **waypoint** - Anchored to a waypoint from an existing group
