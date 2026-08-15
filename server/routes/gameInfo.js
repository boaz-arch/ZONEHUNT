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
    const game =
      gameStore.getGame(
        req.params.code,
      );

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    const playerId =
      req.query.playerId;

    const player =
      game.players.find(
        (p) => p.id === playerId,
      );

    const role =
      player?.role ?? "hider";

    const caught =
      player?.caught ?? false;

    let phase =
      game.state;

    if (phase === "hidePhase") {
      phase = "hide";
    }

    let centerLat =
      game.zoneState?.currentCenterLat ??
      game.zone?.centerLat;

    let centerLng =
      game.zoneState?.currentCenterLng ??
      game.zone?.centerLng;

    let radius =
      game.zoneState?.currentRadius ??
      game.settings.startRadius;

    if (
      game.zoneState?.shrinkStartedAt &&
      game.zoneState?.shrinkEndsAt &&
      game.zoneState?.nextRadius != null
    ) {

      const progress =
        Math.min(
          1,
          Math.max(
            0,
            (
              Date.now() -
              game.zoneState.shrinkStartedAt
            ) /
            (
              game.zoneState.shrinkEndsAt -
              game.zoneState.shrinkStartedAt
            ),
          ),
        );

      radius =
        game.zoneState.shrinkStartRadius +
        (
          game.zoneState.nextRadius -
          game.zoneState.shrinkStartRadius
        ) *
        progress;

      centerLat =
        game.zoneState.shrinkStartCenterLat +
        (
          game.zoneState.nextCenterLat -
          game.zoneState.shrinkStartCenterLat
        ) *
        progress;

      centerLng =
        game.zoneState.shrinkStartCenterLng +
        (
          game.zoneState.nextCenterLng -
          game.zoneState.shrinkStartCenterLng
        ) *
        progress;
    }

    const zone = {
      centerLat,
      centerLng,
      radius,
    };

    res.json({
      phase,
      role,
      caught,
      timerTitle:
        game.zoneState?.phase,
      timerEndsAt:
        game.zoneState?.phaseEndsAt,
      hidePhaseEndsAt:
        game.hidePhaseEndsAt,
      settings:
        game.settings,
      zone,
      zoneState:
        game.zoneState,
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
