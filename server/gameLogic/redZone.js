const gameStore = require("../store/gameStore");
const { randomPointInRadius } = require("../utils/geo");

function startRedZoneSystem(gameCode, io) {
  const game = gameStore.getGame(gameCode);
  if (!game) return;

  const shiftMs = game.settings.redZoneShiftTime * 1000;

  const intervalHandle = setInterval(() => {
    const activeGame = gameStore.getGame(gameCode);

    // BUG FIX: also bail out (and stop the interval outright) once the game
    // is no longer live, not just when it's missing. Belt-and-suspenders
    // alongside clearGameTimers(), in case this tick was already queued
    // when the game ended.
    if (!activeGame || activeGame.state !== "gameplay") {
      clearInterval(intervalHandle);
      return;
    }

    const point = randomPointInRadius(
      activeGame.zone.centerLat,
      activeGame.zone.centerLng,
      activeGame.settings.startRadius,
    );

    io.to(gameCode).emit("redZoneUpdated", {
      lat: point.lat,
      lng: point.lng,
      radius: activeGame.settings.redZoneRadius,
    });
  }, shiftMs);

  gameStore.registerTimer(gameCode, intervalHandle);
}

module.exports = { startRedZoneSystem };
