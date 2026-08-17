const express = require("express");
 
const gameStore = require("../store/gameStore");
const { loadGame, requireHost } = require("../middleware/game");
const { assignRoles } = require("../gameLogic/roles");
const { startZoneShrinking } = require("../gameLogic/zoneShrinking");
const { startRedZoneSystem } = require("../gameLogic/redZone");
const { eliminatePlayer } = require("../gameLogic/elimination");
 
function buildGameplayRouter(io) {
  const router = express.Router();
 
  router.post("/update-position", loadGame, (req, res) => {
 
    const { playerId, lat, lng } = req.body;
 
    const player = req.game.players.find((p) => p.id === playerId);

    if (!player) {
      return res.status(404).json({
        success: false,
      });
    }

    if (
      req.game.state !== "hidePhase" &&
      req.game.state !== "gameplay"
    ) {
      return res.status(400).json({
        success: false,
        message: "Game not active",
      });
    }

    if (player.caught) {
      return res.status(400).json({
        success: false,
        message: "Player caught",
      });
    }
 
    player.position = {
      lat,
      lng,
      lastUpdate: Date.now(),
    };
 
    io.to(req.gameCode).emit(
      "positionsUpdated", 
      req.game.players
    );
 
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

      game.gameplayStarted = false;
 
      game.hidePhaseEndsAt =
        Date.now() + game.settings.hideTime * 60 * 1000;
 
      function beginGameplay(currentGame) {
        if (currentGame.gameplayStarted) {
          return;
        }

        currentGame.gameplayStarted = true;
        currentGame.state = "gameplay";
 
        currentGame.nextZoneStartsAt =
          Date.now() + currentGame.settings.zoneWaitTime * 60 * 1000;
 
        io.to(gameCode).emit("zoneTimerUpdated", {
          phase: "NEXT SHRINK",
          phaseEndsAt: null,
        });
 
        startZoneShrinking(gameCode, io);
        startRedZoneSystem(gameCode, io);
 
        gameStore.registerTimer(
          gameCode,
          setInterval(() => {
 
            const game =
              gameStore.getGame(gameCode);
 
            if (!game) return;
 
            if (game.state !== "gameplay") {
              return;
            }
 
            const {
              distanceMeters,
            } = require("../utils/geo");
 
            for (const player of game.players) {
 
              if (player.caught) continue;

              if (player.caught) {
                io.to(gameCode).emit(
                  "outsideZoneUpdated",
                  {
                    playerId: player.id,
                    remainingSeconds: null,
                  },
                );

                continue;
              }
              
              if (
                !player.position ||
                player.position.lat == null ||
                player.position.lng == null
              ) {
                continue;
              }
 
              let zoneLat =
                game.zoneState.currentCenterLat;
 
              let zoneLng =
                game.zoneState.currentCenterLng;
 
              let zoneRadius =
                game.zoneState.currentRadius;
 
              if (
                game.zoneState.shrinkStartedAt &&
                game.zoneState.shrinkEndsAt &&
                game.zoneState.nextRadius != null
              ) {
 
                const now = Date.now();
 
                const progress =
                  Math.min(
                    1,
                    Math.max(
                      0,
                      (
                        now -
                        game.zoneState.shrinkStartedAt
                      ) /
                      (
                        game.zoneState.shrinkEndsAt -
                        game.zoneState.shrinkStartedAt
                      ),
                    ),
                  );
 
                zoneRadius =
                  game.zoneState.shrinkStartRadius +
                  (
                    game.zoneState.nextRadius -
                    game.zoneState.shrinkStartRadius
                  ) *
                  progress;
 
                zoneLat =
                  game.zoneState.shrinkStartCenterLat +
                  (
                    game.zoneState.nextCenterLat -
                    game.zoneState.shrinkStartCenterLat
                  ) *
                  progress;
 
                zoneLng =
                  game.zoneState.shrinkStartCenterLng +
                  (
                    game.zoneState.nextCenterLng -
                    game.zoneState.shrinkStartCenterLng
                  ) *
                  progress;
              }
 
              const distance =
                distanceMeters(
                  player.position.lat,
                  player.position.lng,
                  zoneLat,
                  zoneLng,
                );
 
              const outsideZone =
                distance > zoneRadius;
 
              if (!outsideZone) {
 
                player.outsideZoneSince =
                  null;
 
                io.to(gameCode).emit(
                  "outsideZoneUpdated",
                  {
                    playerId: player.id,
                    remainingSeconds: null,
                  },
                );
 
                continue;
              }
 
              if (!player.outsideZoneSince) {
                player.outsideZoneSince =
                  Date.now();
              }
 
              const elapsedMs =
                Date.now() -
                player.outsideZoneSince;
 
              const limitMs =
                game.settings.outsideZoneTime *
                1000;
 
              const remainingSeconds =
                Math.max(
                  0,
                  Math.ceil(
                    (limitMs - elapsedMs) / 1000,
                  ),
                );
 
              io.to(gameCode).emit(
                "outsideZoneUpdated",
                {
                  playerId: player.id,
                  remainingSeconds,
                },
              );
 
              if (
                elapsedMs < limitMs
              ) {
                continue;
              }
 
              eliminatePlayer(
                gameCode,
                player.id,
                io,
              );
            }
          }, 1000),
        );
 
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
 
    const success = eliminatePlayer(
      gameCode,
      playerId,
      io,
    );

    res.json({ success });
  });
 
  return router;
}
 
module.exports = buildGameplayRouter;