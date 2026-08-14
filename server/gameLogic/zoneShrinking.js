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

  // Returns the game only if it still exists AND is still actively playing.
  // BUG FIX: previously these callbacks only checked `if (!game) return`,
  // never `game.state`. Since /mark-caught marks a finished game as "ended"
  // instead of deleting it, a callback that was already mid-flight when the
  // game ended would sail past that check and schedule its *next* timer
  // anyway - so clearGameTimers() alone couldn't fully stop the chain (it
  // can only cancel timers that haven't fired yet, not ones already
  // executing). Checking state here closes that race.
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

    io.to(gameCode).emit("zoneTimerUpdated", {
      phase: "SHRINKING",
      phaseEndsAt: Date.now() + zoneShrinkMs,
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

          io.to(gameCode).emit("zoneTimerUpdated", {
            phase: "FINAL ZONE",
            phaseEndsAt: null,
          });

          return;
        }

        createPreviewZone(finishedGame);

        io.to(gameCode).emit("zoneTimerUpdated", {
          phase: "NEXT SHRINK",
          phaseEndsAt: Date.now() + zoneWaitMs,
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

      io.to(gameCode).emit("zoneTimerUpdated", {
        phase: "NEXT SHRINK",
        phaseEndsAt: Date.now() + zoneWaitMs,
      });

      createPreviewZone(currentGame);

      gameStore.registerTimer(gameCode, setTimeout(startShrink, zoneWaitMs));
    }, zoneWaitMs),
  );
}

module.exports = { startZoneShrinking };
