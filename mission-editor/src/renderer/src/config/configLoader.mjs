/**
 * Configuration Loader - Pure JS logic for loading and managing mission configuration
 *
 * This module contains testable logic that can be used by both:
 * - Vue stores (through Pinia wrappers)
 * - Node.js CLI for testing
 *
 * No Vue/Pinia/Electron dependencies - pure JavaScript.
 */

// ==============================================================================
// REFPOINTS LOADER
// ==============================================================================

export const VALID_BULLSEYES = ['Red', 'Blue', 'Neutral'];

/**
 * Load reference points from full config into a store-like object
 * @param {Object} store - Object with bullseyes, airbases, zones, lines arrays
 * @param {Object} fullConfig - Full configuration object
 */
export function loadRefpointsFromConfig(store, fullConfig) {
  const refpoints = fullConfig.refpoints || {};
  const existingNames = new Set();

  // Collect existing names to track duplicates
  store.bullseyes.forEach(b => existingNames.add(b.name));
  store.airbases.forEach(ab => existingNames.add(ab.name));
  store.zones.forEach(z => existingNames.add(z.name));
  store.lines.forEach(l => existingNames.add(l.name));

  // Load bullseyes
  (refpoints.bullseyes || []).forEach(b => {
    const validatedName = VALID_BULLSEYES.find(n => n.toLowerCase() === b.name.toLowerCase());
    if (validatedName) {
      let name = validatedName;
      let counter = 1;
      while (existingNames.has(name)) {
        name = `${validatedName}_${counter}`;
        counter++;
      }
      existingNames.add(name);
      store.bullseyes.push({ name });
    }
  });

  // Load airbases
  (refpoints.airbases || []).forEach(ab => {
    let name = ab.name;
    let counter = 1;
    while (existingNames.has(name)) {
      name = `${ab.name}_${counter}`;
      counter++;
    }
    existingNames.add(name);
    store.airbases.push({ name });
  });

  // Load zones
  (refpoints.zones || []).forEach(z => {
    let name = z.name;
    let counter = 1;
    while (existingNames.has(name)) {
      name = `${z.name}_${counter}`;
      counter++;
    }
    existingNames.add(name);
    store.zones.push({ name });
  });

  // Load lines
  (refpoints.lines || []).forEach(l => {
    let name = l.name;
    let counter = 1;
    while (existingNames.has(name)) {
      name = `${l.name}_${counter}`;
      counter++;
    }
    existingNames.add(name);
    store.lines.push({
      name,
      startX: l.startX || 0,
      startY: l.startY || 0,
      endX: l.endX || 0,
      endY: l.endY || 0
    });
  });
}

/**
 * Load units from full config
 * @param {Array} units - Array to load units into
 * @param {Object} fullConfig - Full configuration object
 * @param {string} unitsKey - Key to use for units ('units' or 'groups')
 */
export function loadUnitsFromConfig(units, fullConfig, unitsKey = 'units') {
  const configUnits = fullConfig[unitsKey] || fullConfig.groups || [];
  units.push(...configUnits);
}

// ==============================================================================
// TEMPLATE LOADER
// ==============================================================================

/**
 * Merge templates with duplicate handling
 * @param {Array} existing - Existing templates
 * @param {Array} newItems - New templates to merge
 * @returns {Array} Merged array
 */
export function mergeTemplates(existing, newItems) {
  if (!Array.isArray(existing)) existing = [];
  if (!Array.isArray(newItems)) newItems = [];

  // Build set of existing IDs
  const existingIds = new Set();
  for (const item of existing) {
    if (item && item.id) {
      existingIds.add(item.id);
    }
  }

  // Build set of new IDs to track duplicates within newItems
  const newIds = new Set();
  for (const item of newItems) {
    if (item && item.id) {
      newIds.add(item.id);
    }
  }

  const result = [...existing];
  for (const item of newItems) {
    if (!item || !item.id) continue;

    let currentId = item.id;
    let counter = 1;

    // Keep renaming until we find a unique ID
    while (existingIds.has(currentId) || newIds.has(currentId)) {
      currentId = `${item.id}_${counter}`;
      counter++;
    }

    if (currentId !== item.id) {
      item.id = currentId;
    }

    newIds.add(currentId);
    existingIds.add(currentId);
    result.push(item);
  }

  return result;
}

/**
 * Load unit templates from config into store
 * @param {Object} store - Store with categories object
 * @param {Object} fullConfig - Full configuration object
 */
export function loadUnitTemplatesFromConfig(store, fullConfig) {
  const templates = fullConfig.unit_templates || {};
  for (const [key, items] of Object.entries(templates)) {
    if (items && Array.isArray(items)) {
      const category = key.replace('_templates', '');
      if (store.categories[category]) {
        store.categories[category] = mergeTemplates(store.categories[category], items);
      }
    }
  }
}

/**
 * Load route templates from config
 * @param {Array} routeTemplates - Array to load route templates into
 * @param {Object} fullConfig - Full configuration object
 */
export function loadRouteTemplatesFromConfig(routeTemplates, fullConfig) {
  const templateConfig = fullConfig.route_templates || {};
  if (templateConfig) {
    Object.entries(templateConfig).forEach(([key, value]) => {
      if (!routeTemplates.find(t => t.id === key)) {
        routeTemplates.push({ id: key, ...value });
      }
    });
  }
}

// ==============================================================================
// CONFIG LOADER - High level API
// ==============================================================================

/**
 * Load a complete configuration into a store object
 * @param {Object} store - Store object to populate
 * @param {Object} fullConfig - Full configuration object
 */
export function loadFullConfig(store, fullConfig) {
  loadRefpointsFromConfig(store, fullConfig);
  loadUnitsFromConfig(store.units || [], fullConfig);
  loadUnitTemplatesFromConfig(store.unitTemplates || {}, fullConfig);
  loadRouteTemplatesFromConfig(store.routeTemplates || [], fullConfig);
}
