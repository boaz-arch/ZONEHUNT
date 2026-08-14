const express = require("express");

const gameStore = require("../store/gameStore");
const { loadGame, requireHost } = require("../middleware/game");
const { assignRoles } = require("../gameLogic/roles");
const { startZoneShrinking } = require("../gameLogic/zoneShrinking");
const { startRedZoneSystem } = require("../gameLogic/redZone");

function buildGameplayRouter(io) {
  const router = express.Router();

  router.post("/update-position", loadGame, (req, res) => {
    const { playerId, lat, lng } = req.body;

    const player = req.game.players.find((p) => p.id === playerId);

    if (!player) {
      return res.status(404).json({ success: false });
    }

    player.position = {
      lat,
      lng,
      lastUpdate: Date.now(),
    };

    console.log(
      req.game.players.map((p) => ({
        name: p.name,
        id: p.id,
        role: p.role,
        lat: p.position.lat,
        lng: p.position.lng,
      })),
    );

    io.to(req.gameCode).emit("positionsUpdated", req.game.players);

    res.json({ success: true });
  });

  router.get("/positions/:code", (req, res) => {
    const game = gameStore.getGame(req.params.code);

    if (!game) {
      return res.status(404).json({ success: false });
    }

    res.json(
      game.players.map((p) => ({
        id: p.id,
        name: p.name,
        role: p.role,
        caught: p.caught,
        position: p.position,
      })),
    );
  });

  router.post(
    "/start-game",
    loadGame,
    requireHost,
    (req, res) => {
      const game = req.game;
      const gameCode = req.gameCode;

      if (game.state !== "lobby") {
        return res.status(400).json({
          success: false,
          message: "Game already started",
        });
      }

      assignRoles(game);

      game.state = "hidePhase";

      game.zoneState = {
        currentZoneNumber: 1,

        currentCenterLat: game.zone.centerLat,
        currentCenterLng: game.zone.centerLng,

        currentRadius: game.settings.startRadius,

        nextCenterLat: null,
        nextCenterLng: null,
        nextRadius: null,

        phase: "waiting",
        phaseEndsAt: null,
      };

      game.hidePhaseEndsAt =
        Date.now() + game.settings.hideTime * 60 * 1000;

      function beginGameplay(currentGame) {
        currentGame.state = "gameplay";

        currentGame.nextZoneStartsAt =
          Date.now() + currentGame.settings.zoneWaitTime * 60 * 1000;

        io.to(gameCode).emit("zoneTimerUpdated", {
          phase: "NEXT SHRINK",
          phaseEndsAt: null,
        });

        startZoneShrinking(gameCode, io);
        startRedZoneSystem(gameCode, io);

        io.to(gameCode).emit("gameplayStarted", {
          zone: {
            centerLat: currentGame.zoneState.currentCenterLat,
            centerLng: currentGame.zoneState.currentCenterLng,
          },
          currentRadius: currentGame.zoneState.currentRadius,
          zoneState: currentGame.zoneState,
        });
      }

      const hideMs = game.settings.hideTime * 60 * 1000;

      if (hideMs <= 0) {
        beginGameplay(game);
      } else {
        gameStore.registerTimer(
          gameCode,
          setTimeout(() => {
            const currentGame = gameStore.getGame(gameCode);
            if (!currentGame) return;

            if (currentGame.state !== "hidePhase") {
              return;
            }

            beginGameplay(currentGame);
          }, hideMs),
        );
      }

      io.to(gameCode).emit("gameStarted", game);

      res.json({ success: true });
    },
  );

  router.post("/mark-caught", loadGame, (req, res) => {
    const { playerId } = req.body;
    const game = req.game;
    const gameCode = req.gameCode;

    const player = game.players.find((p) => p.id === playerId);

    if (!player) {
      return res.status(404).json({ success: false });
    }

    player.caught = true;

    const aliveHiders = game.players.filter(
      (p) => p.role === "hider" && !p.caught,
    );

    if (aliveHiders.length === 0) {
      game.state = "ended";

      // BUG FIX: the zone-shrinking timeout chain and the red-zone
      // setInterval were never stopped when a game ended. They'd keep
      // running in the background for the rest of the process's
      // lifetime, still emitting to (now-empty) game rooms. Cancel them
      // as soon as the game is over.
      gameStore.clearGameTimers(gameCode);

      io.to(gameCode).emit("gameEnded", {
        winner: "Hunters",
      });
    }

    io.to(gameCode).emit("playerCaught", {
      playerId,
      players: game.players,
    });

    res.json({ success: true });
  });

  return router;
}

module.exports = buildGameplayRouter;
