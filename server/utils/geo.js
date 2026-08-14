const METERS_PER_DEGREE_LAT = 111320;

/**
 * Picks a uniformly random point within `maxRadiusMeters` of (centerLat, centerLng).
 * This is the single implementation of the offset math that used to be duplicated
 * in generateRandomZoneInside() and inline inside startRedZoneSystem().
 */
function randomPointInRadius(centerLat, centerLng, maxRadiusMeters) {
  const angle = Math.random() * 2 * Math.PI;
  const distance = Math.random() * maxRadiusMeters;

  const latOffset =
    (distance / METERS_PER_DEGREE_LAT) * Math.cos(angle);

  const lngOffset =
    (distance /
      (METERS_PER_DEGREE_LAT * Math.cos(centerLat * (Math.PI / 180)))) *
    Math.sin(angle);

  return {
    lat: centerLat + latOffset,
    lng: centerLng + lngOffset,
  };
}

/**
 * Picks a random point inside `currentRadius` that still leaves room for a
 * zone of `nextRadius` to fit inside it (used for shrinking the safe zone).
 */
function generateRandomZoneInside(
  centerLat,
  centerLng,
  currentRadius,
  nextRadius,
) {
  const maxOffset = currentRadius - nextRadius;
  const point = randomPointInRadius(centerLat, centerLng, maxOffset);

  return {
    centerLat: point.lat,
    centerLng: point.lng,
  };
}

module.exports = {
  randomPointInRadius,
  generateRandomZoneInside,
};
