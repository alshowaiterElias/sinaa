/**
 * Geolocation Utilities
 * 
 * Functions for distance calculations and location-based queries.
 */

/**
 * Calculate distance between two points using Haversine formula.
 * 
 * @param lat1 - Latitude of first point in degrees
 * @param lon1 - Longitude of first point in degrees
 * @param lat2 - Latitude of second point in degrees
 * @param lon2 - Longitude of second point in degrees
 * @returns Distance in kilometers
 */
export const calculateDistance = (
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
): number => {
    const EARTH_RADIUS_KM = 6371;

    // Convert degrees to radians
    const toRadians = (degrees: number): number => degrees * (Math.PI / 180);

    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadians(lat1)) *
        Math.cos(toRadians(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return EARTH_RADIUS_KM * c;
};

/**
 * Round distance to 1 decimal place for display.
 * 
 * @param distance - Distance in kilometers
 * @returns Rounded distance
 */
export const formatDistance = (distance: number): number => {
    return Math.round(distance * 10) / 10;
};

/**
 * Check if a point is within a radius of another point.
 * 
 * @param centerLat - Center point latitude
 * @param centerLon - Center point longitude
 * @param pointLat - Point to check latitude
 * @param pointLon - Point to check longitude
 * @param radiusKm - Radius in kilometers
 * @returns True if point is within radius
 */
export const isWithinRadius = (
    centerLat: number,
    centerLon: number,
    pointLat: number,
    pointLon: number,
    radiusKm: number
): boolean => {
    const distance = calculateDistance(centerLat, centerLon, pointLat, pointLon);
    return distance <= radiusKm;
};

/**
 * Get bounding box coordinates for a radius around a point.
 * Used for initial filtering before precise distance calculation.
 * 
 * @param lat - Center latitude
 * @param lon - Center longitude
 * @param radiusKm - Radius in kilometers
 * @returns Bounding box with min/max lat/lon
 */
export const getBoundingBox = (
    lat: number,
    lon: number,
    radiusKm: number
): {
    minLat: number;
    maxLat: number;
    minLon: number;
    maxLon: number;
} => {
    // Approximate degrees per km (varies by latitude)
    const latDegPerKm = 1 / 111.32;
    const lonDegPerKm = 1 / (111.32 * Math.cos(lat * (Math.PI / 180)));

    const latOffset = radiusKm * latDegPerKm;
    const lonOffset = radiusKm * lonDegPerKm;

    return {
        minLat: lat - latOffset,
        maxLat: lat + latOffset,
        minLon: lon - lonOffset,
        maxLon: lon + lonOffset,
    };
};

/**
 * Validate latitude value.
 * 
 * @param lat - Latitude to validate
 * @returns True if valid latitude (-90 to 90)
 */
export const isValidLatitude = (lat: number): boolean => {
    return !isNaN(lat) && lat >= -90 && lat <= 90;
};

/**
 * Validate longitude value.
 * 
 * @param lon - Longitude to validate
 * @returns True if valid longitude (-180 to 180)
 */
export const isValidLongitude = (lon: number): boolean => {
    return !isNaN(lon) && lon >= -180 && lon <= 180;
};

/**
 * Default search radius in kilometers.
 */
export const DEFAULT_SEARCH_RADIUS_KM = 50;

/**
 * Maximum search radius in kilometers.
 */
export const MAX_SEARCH_RADIUS_KM = 100;
