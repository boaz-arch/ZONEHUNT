const express = require("express");

const gameStore = require("../store/gameStore");

function buildGameInfoRouter() {
  const router = express.Router();

  router.get("/", (req, res) => {
    res.send("ZoneHunt API Online");
  });

  router.get("/game/:code", (req, res) => {
    const game = gameStore.getGame(req.params.code);

    if (!game) {
      return res.status(404).json({ success: false });
    }

    res.json(game);
  });

  router.get("/game-state/:code", (req, res) => {
    const game = gameStore.getGame(req.params.code);

    if (!game) {
      return res.status(404).json({ success: false });
    }

    res.json({
      state: game.state,
      hidePhaseEndsAt: game.hidePhaseEndsAt,
      players: game.players,
      settings: game.settings,
      zone: game.zone,
      zoneState: game.zoneState,
    });
  });

  router.get("/games", (req, res) => {
    res.json(gameStore.games);
  });

  router.get("/test-state/:code", (req, res) => {
    const game = gameStore.getGame(req.params.code);

    if (!game) {
      return res.status(404).json({ success: false });
    }

    res.json(game.zoneState);
  });

  return router;
}

module.exports = buildGameInfoRouter;
