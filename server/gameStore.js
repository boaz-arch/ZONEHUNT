const { randomUUID } = require("crypto");

// Same shared object as before - routes like GET /games and GET /game/:code
// still return this directly, so its shape is unchanged.
const games = {};

// Tracks every setTimeout/setInterval handle a game's background logic has
// scheduled (zone shrinking chain, red zone interval), keyed by gameCode.
// This is what lets us cancel them once a game ends - see clearGameTimers().
const gameTimers = {};

function createGame(gameCode, gameData) {
  games[gameCode] = gameData;
  gameTimers[gameCode] = [];
  return games[gameCode];
}

function getGame(gameCode) {
  return games[gameCode];
}

function deleteGame(gameCode) {
  clearGameTimers(gameCode);
  delete games[gameCode];
}

/**
 * Registers a timer (returned by setTimeout or setInterval) against a game,
 * so it gets cleaned up automatically if the game ends. Always wrap
 * background timers for a game with this instead of calling
 * setTimeout/setInterval directly.
 */
function registerTimer(gameCode, timerHandle) {
  if (!gameTimers[gameCode]) {
    gameTimers[gameCode] = [];
  }
  gameTimers[gameCode].push(timerHandle);
  return timerHandle;
}

/**
 * Cancels every pending timeout/interval that background game logic has
 * scheduled for this game. In Node.js, clearTimeout() and clearInterval()
 * are interchangeable, so one function can clear both kinds.
 *
 * BUG FIX: previously, nothing ever called clearInterval on the red-zone
 * interval or clearTimeout on the zone-shrinking chain. Once a game ended
 * (e.g. all hiders caught, in /mark-caught), those timers kept firing
 * forever - continuing to emit "redZoneUpdated"/"zoneUpdated" events to a
 * game that was already over, and leaking a setInterval per finished game
 * for the lifetime of the server process.
 */
function clearGameTimers(gameCode) {
  const timers = gameTimers[gameCode];
  if (!timers) return;

  for (const handle of timers) {
    clearTimeout(handle);
  }

  gameTimers[gameCode] = [];
}

function generatePlayerId() {
  return randomUUID();
}

module.exports = {
  games,
  createGame,
  getGame,
  deleteGame,
  registerTimer,
  clearGameTimers,
  generatePlayerId,
};
