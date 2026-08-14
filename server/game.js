const gameStore = require("../store/gameStore");

function getHostPlayer(game, playerId) {
  const player = game.players.find((p) => p.id === playerId);

  if (!player) return null;
  if (!player.host) return null;

  return player;
}

/**
 * Looks up the game from req.body.gameCode (or req.params.code) and attaches
 * it as req.game. Replaces the repeated
 *   const game = games[gameCode];
 *   if (!game) return res.status(404).json({ success: false });
 * block that appeared in nearly every route.
 */
function loadGame(req, res, next) {
  const gameCode = req.body.gameCode || req.params.code;
  const game = gameStore.getGame(gameCode);

  if (!game) {
    return res.status(404).json({
      success: false,
      message: "Game not found",
    });
  }

  req.gameCode = gameCode;
  req.game = game;
  next();
}

/**
 * Must run after loadGame. Replaces the repeated
 *   const host = getHostPlayer(game, playerId);
 *   if (!host) return res.status(403).json({ ... });
 * block.
 */
function requireHost(req, res, next) {
  const playerId = req.body.playerId;
  const host = getHostPlayer(req.game, playerId);

  if (!host) {
    return res.status(403).json({
      success: false,
      message: "Only the host can perform this action",
    });
  }

  req.hostPlayer = host;
  next();
}

module.exports = {
  getHostPlayer,
  loadGame,
  requireHost,
};
