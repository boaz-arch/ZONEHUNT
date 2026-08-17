const gameStore = require("../store/gameStore");
const { generateRandomZoneInside } = require("../utils/geo");
 
function startZoneShrinking(gameCode, io) {
  const game = gameStore.getGame(gameCode);
  if (!game) return;
 
  const zoneCount = game.settings.zoneCount;
  const startRadius = game.settings.startRadius;
  const finalRadius = game.settings.finalRadius;
 
  const zoneWaitMs = game.settings.zoneWaitTime * 60 * 1000;
  const zoneShrinkMs = game.settings.zoneShrinkTime * 60 * 1000;
 
  const radiusStep =
    zoneCount <= 1 ? 0 : (startRadius - finalRadius) / (zoneCount - 1);
 
  function getLiveGame() {
    const currentGame = gameStore.getGame(gameCode);
    if (!currentGame) return null;
    if (currentGame.state !== "gameplay") return null;
    return currentGame;
  }
 
  function createPreviewZone(currentGame) {
    if (currentGame.zoneState.currentZoneNumber >= zoneCount) {
      return false;
    }
 
    const nextRadius = Math.max(
      finalRadius,
      Math.round(
        startRadius - radiusStep * currentGame.zoneState.currentZoneNumber,
      ),
    );
 
    const nextZone = generateRandomZoneInside(
      currentGame.zoneState.currentCenterLat,
      currentGame.zoneState.currentCenterLng,
      currentGame.zoneState.currentRadius,
      nextRadius,
    );
 
    currentGame.zoneState.nextCenterLat = nextZone.centerLat;
    currentGame.zoneState.nextCenterLng = nextZone.centerLng;
    currentGame.zoneState.nextRadius = nextRadius;
 
    io.to(gameCode).emit("zoneUpdated", {
      durationMs: 0,
      zoneState: currentGame.zoneState,
    });
 
    return true;
  }
 
  function startShrink() {
    const activeGame = getLiveGame();
    if (!activeGame) return;
 
    if (activeGame.zoneState.currentZoneNumber >= zoneCount) {
      return;
    }
 
    activeGame.zoneState.currentZoneNumber++;
 
    activeGame.zoneState.phase =
      "SHRINKING";
 
    activeGame.zoneState.phaseEndsAt =
      Date.now() + zoneShrinkMs;
 
    io.to(gameCode).emit("zoneTimerUpdated", {
      phase: activeGame.zoneState.phase,
      phaseEndsAt:
        activeGame.zoneState.phaseEndsAt,
    });
 
    activeGame.zoneState.shrinkStartedAt =
      Date.now();
 
    activeGame.zoneState.shrinkEndsAt =
      Date.now() + zoneShrinkMs;
 
    activeGame.zoneState.shrinkStartRadius =
      activeGame.zoneState.currentRadius;
 
    activeGame.zoneState.shrinkStartCenterLat =
      activeGame.zoneState.currentCenterLat;
 
    activeGame.zoneState.shrinkStartCenterLng =
      activeGame.zoneState.currentCenterLng;
 
    io.to(gameCode).emit("zoneUpdated", {
      durationMs: zoneShrinkMs,
      zoneState: activeGame.zoneState,
    });
 
    gameStore.registerTimer(
      gameCode,
      setTimeout(() => {
        const finishedGame = getLiveGame();
        if (!finishedGame) return;
 
        finishedGame.zoneState.currentCenterLat =
          finishedGame.zoneState.nextCenterLat;
 
        finishedGame.zoneState.currentCenterLng =
          finishedGame.zoneState.nextCenterLng;
 
        finishedGame.zoneState.currentRadius =
          finishedGame.zoneState.nextRadius;
 
        finishedGame.zoneState.shrinkStartedAt =
          null;
 
        finishedGame.zoneState.shrinkEndsAt =
          null;
 
        finishedGame.zoneState.shrinkStartRadius =
          null;
 
        finishedGame.zoneState.shrinkStartCenterLat =
          null;
 
        finishedGame.zoneState.shrinkStartCenterLng =
          null;
 
        if (finishedGame.zoneState.currentZoneNumber >= zoneCount) {
          finishedGame.zoneState.nextCenterLat = null;
          finishedGame.zoneState.nextCenterLng = null;
          finishedGame.zoneState.nextRadius = null;
 
          io.to(gameCode).emit("zoneUpdated", {
            durationMs: 0,
            zoneState: finishedGame.zoneState,
          });
 
          finishedGame.zoneState.phase =
            "FINAL ZONE";
 
          finishedGame.zoneState.phaseEndsAt =
            null;
 
          io.to(gameCode).emit("zoneTimerUpdated", {
            phase: finishedGame.zoneState.phase,
            phaseEndsAt:
              finishedGame.zoneState.phaseEndsAt,
          });
 
          return;
        }
 
        createPreviewZone(finishedGame);
 
        finishedGame.zoneState.phase =
          "NEXT SHRINK";
 
        finishedGame.zoneState.phaseEndsAt =
          Date.now() + zoneWaitMs;
 
        io.to(gameCode).emit("zoneTimerUpdated", {
          phase: finishedGame.zoneState.phase,
          phaseEndsAt:
            finishedGame.zoneState.phaseEndsAt,
        });
 
        gameStore.registerTimer(
          gameCode,
          setTimeout(startShrink, zoneWaitMs),
        );
      }, zoneShrinkMs),
    );
  }
 
  // Initial wait after gameplay starts
  gameStore.registerTimer(
    gameCode,
    setTimeout(() => {
      const currentGame = getLiveGame();
      if (!currentGame) return;
 
      currentGame.zoneState.phase =
        "NEXT SHRINK";
 
      currentGame.zoneState.phaseEndsAt =
        Date.now() + zoneWaitMs;
 
      io.to(gameCode).emit("zoneTimerUpdated", {
        phase: currentGame.zoneState.phase,
        phaseEndsAt:
          currentGame.zoneState.phaseEndsAt,
      });
 
      createPreviewZone(currentGame);
 
      gameStore.registerTimer(gameCode, setTimeout(startShrink, zoneWaitMs));
    }, zoneWaitMs),
  );
}
 
module.exports = { startZoneShrinking };