const gameStore = require("../store/gameStore");

function eliminatePlayer(gameCode, playerId, io) {
  const game = gameStore.getGame(gameCode);

  // Validate game state before acting on it.
  if (!game || game.state !== "gameplay") {
    return false;
  }

  const player = game.players.find((p) => p.id === playerId);

  // Validate player state before acting on it.
  if (!player || player.caught) {
    return false;
  }

  if (player.role !== "hider") {
    // Hunters aren't "caught" through this path.
    return false;
  }

  player.caught = true;
  player.outsideZoneSince = null;

  // The only place "playerCaught" is emitted from — guarantees exactly
  // one emit per elimination, no matter which call site triggered it.
  io.to(gameCode).emit("playerCaught", {
    playerId: player.id,
    players: game.players,
  });

  maybeEndGameByElimination(game, gameCode, io);

  return true;
}

function maybeEndGameByElimination(game, gameCode, io) {
  if (game.state !== "gameplay") return;

  const aliveHiders = game.players.filter(
    (p) => p.role === "hider" && !p.caught,
  );

  if (aliveHiders.length > 0) return;

  endGame(game, gameCode, io, "hunters");
}

function endGame(game, gameCode, io, winner) {
  if (game.state === "ended") return false;

  game.state = "ended";
  game.gameplayStarted = false;

  gameStore.clearGameTimers(gameCode);

  io.to(gameCode).emit("gameEnded", { winner });

  return true;
}

module.exports = { eliminatePlayer, endGame, maybeEndGameByElimination };
