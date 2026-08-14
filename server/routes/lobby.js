const express = require("express");

const gameStore = require("../store/gameStore");
const { loadGame, requireHost } = require("../middleware/game");
const { generateGameCode } = require("../gameLogic/roles");

function buildLobbyRouter(io) {
  const router = express.Router();

  router.post("/create-game", (req, res) => {
    const { playerName, lat, lng } = req.body;

    const gameCode = generateGameCode();

    const game = gameStore.createGame(gameCode, {
      gameCode,

      state: "lobby",

      settings: {
        gameDuration: 60,
        hideTime: 5,

        hunterCount: 1,

        zoneCount: 5,

        startRadius: 1000,
        finalRadius: 100,

        zoneWaitTime: 5,
        zoneShrinkTime: 3,

        redZoneRadius: 50,
        redZoneShiftTime: 120,

        anonymousMode: false,
        randomFutureZones: true,

        outsideZoneTime: 10,
      },

      zone: {
        centerLat: lat,
        centerLng: lng,
      },

      players: [
        {
          id: gameStore.generatePlayerId(),
          name: playerName,
          host: true,
          role: null,
          caught: false,
          outsideZoneSince: null,
          position: {
            lat: null,
            lng: null,
            lastUpdate: null,
          },
        }
      ],
    });

    res.json({
      success: true,
      gameCode,
      playerId: game.players[0].id,
    });
  });

  router.post("/join-game", (req, res) => {
    const { gameCode, playerName } = req.body;

    const game = gameStore.getGame(gameCode);

    if (!game) {
      return res.status(404).json({
        success: false,
        message: "Game not found",
      });
    }

    if (game.state !== "lobby") {
      return res.status(400).json({
        success: false,
        message: "Game already started",
      });
    }

    const player = {
      id: gameStore.generatePlayerId(),
      name: playerName,
      host: false,
      role: null,
      caught: false,
      outsideZoneSince: null,
      position: {
        lat: null,
        lng: null,
        lastUpdate: null,
      },
    };

    game.players.push(player);

    io.to(gameCode).emit("lobbyUpdated", game);

    res.json({
      success: true,
      playerId: player.id,
    });
  });

  router.post(
    "/update-settings",
    loadGame,
    requireHost,
    (req, res) => {
      req.game.settings = req.body.settings;

      io.to(req.gameCode).emit("lobbyUpdated", req.game);

      res.json({ success: true });
    },
  );

  router.post(
    "/update-zone-center",
    loadGame,
    requireHost,
    (req, res) => {
      const { centerLat, centerLng } = req.body;

      req.game.zone = { centerLat, centerLng };

      io.to(req.gameCode).emit("lobbyUpdated", req.game);

      res.json({ success: true });
    },
  );

  return router;
}

module.exports = buildLobbyRouter;
