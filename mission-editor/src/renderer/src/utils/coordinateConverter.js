/**
 * Coordinate conversion utilities for DCS World
 * Shared between main process and renderer
 *
 * NOTE: This file is duplicated in src/main/mizParser.js for Node.js usage.
 * When updating THEATER_PROJECTIONS or the latLonToDCS algorithm, update BOTH files.
 */

/**
 * WGS84 ellipsoid constants - computed once at module load
 */
const ELLIPSOID_A = 6378137.0
const E = 0.081819190842621
const N = (1 - Math.sqrt(1 - E * E)) / (1 + Math.sqrt(1 - E * E))
const A = ELLIPSOID_A * (1 - N) / (1 + N) * (1 + N * N / 4 + N * N * N * N / 64)
const ALPHA = [
  A * (1 + N * N / 4 + N * N * N * N / 64),
  -A * (3 * N / 2 - 9 * N * N * N / 32 + 9 * N * N * N * N * N / 512),
  A * (15 * N * N / 16 - 15 * N * N * N * N / 256),
  -A * (35 * N * N * N / 48 - 175 * N * N * N * N * N / 3072)
]

/**
 * Projection parameters for each DCS theater
 * See mizParser.js for detailed documentation
 */
export const THEATER_PROJECTIONS = {
  // VERIFIED - derived from Batumi airbase coordinates in actual MIZ file
  'Caucasus': { lat0: 0, lon0: 33, k0: 0.9996, x0: -1076497, y0: -3986242 },

  // UNVERIFIED - lat0/lon0 are geographic estimates, x0/y0 are placeholders
  'Normandy': { lat0: 49, lon0: 0, k0: 0.9996, x0: 0, y0: 0 },
  'PersianGulf': { lat0: 0, lon0: 54, k0: 0.9996, x0: 0, y0: 0 },
  'Syria': { lat0: 0, lon0: 38, k0: 0.9996, x0: 0, y0: 0 },
  'Nevada': { lat0: 0, lon0: -116, k0: 0.9996, x0: 0, y0: 0 },
  'Iraq': { lat0: 0, lon0: 44, k0: 0.9996, x0: 0, y0: 0 },
  'TheChannel': { lat0: 49.5, lon0: -1, k0: 0.9996, x0: 0, y0: 0 },
  'Sinai': { lat0: 0, lon0: 34, k0: 0.9996, x0: 0, y0: 0 },
  'SouthAtlantic': { lat0: -52, lon0: -59, k0: 0.9996, x0: 0, y0: 0 },
  'Afghanistan': { lat0: 0, lon0: 67, k0: 0.9996, x0: 0, y0: 0 },
  'Falklands': { lat0: -52, lon0: -59, k0: 0.9996, x0: 0, y0: 0 },
}

/**
 * Convert latitude/longitude to DCS world coordinates (meters)
 * Uses Transverse Mercator projection with theater-specific parameters
 * @param {number} lat - Latitude in degrees
 * @param {number} lon - Longitude in degrees
 * @param {string} theater - Theater name
 * @returns {{x: number, y: number}} DCS world coordinates in meters
 */
export function latLonToDCS(lat, lon, theater = 'Caucasus') {
  const params = THEATER_PROJECTIONS[theater] || THEATER_PROJECTIONS['Caucasus']
  const { lat0, lon0, k0, x0, y0 } = params
  const latRad = lat * Math.PI / 180
  const lonRad = lon * Math.PI / 180
  const lonOriginRad = lon0 * Math.PI / 180
  const v = ELLIPSOID_A / Math.sqrt(1 - E * E * Math.sin(latRad) * Math.sin(latRad))
  const T = Math.tan(latRad) * Math.tan(latRad)
  const C = (E * E) / (1 - E * E) * Math.cos(latRad) * Math.cos(latRad)
  const deltaLon = lonRad - lonOriginRad
  const M = ALPHA[0] * latRad + ALPHA[1] * Math.sin(2 * latRad) + ALPHA[2] * Math.sin(4 * latRad) + ALPHA[3] * Math.sin(6 * latRad)
  const x = x0 + k0 * v * deltaLon * Math.cos(latRad) + k0 * v * Math.pow(deltaLon, 3) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) / 6 * (1 - T + C)
  const y = y0 + k0 * (M + v * Math.tan(latRad) * deltaLon * deltaLon / 2 * Math.cos(latRad) * Math.cos(latRad) + v * Math.tan(latRad) * Math.pow(deltaLon, 4) / 24 * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) * Math.cos(latRad) * (5 - T + 9 * C + 4 * C * C))
  return { x, y }
}
