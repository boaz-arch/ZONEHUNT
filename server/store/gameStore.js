const { randomUUID } = require("crypto");

const games = {};
const gameTimers = {};
const outsideZoneTimers = {};

function createGame(gameCode, gameData) {
  games[gameCode] = gameData;
  gameTimers[gameCode] = [];
  outsideZoneTimers[gameCode] = {};

  return games[gameCode];
}

function getGame(gameCode) {
  return games[gameCode];
}

function deleteGame(gameCode) {
  clearGameTimers(gameCode);
  delete outsideZoneTimers[gameCode];
  delete games[gameCode];
}

function registerTimer(gameCode, timerHandle) {
  if (!gameTimers[gameCode]) {
    gameTimers[gameCode] = [];
  }
  gameTimers[gameCode].push(timerHandle);
  return timerHandle;
}

function clearGameTimers(gameCode) {
  const timers = gameTimers[gameCode];
  if (!timers) return;

  for (const handle of timers) {
    clearTimeout(handle);
    clearInterval(handle);
  }

  gameTimers[gameCode] = [];

  const zoneTimers =
  outsideZoneTimers[gameCode];

  if (zoneTimers) {

    for (const playerId in zoneTimers) {
      clearTimeout(zoneTimers[playerId]);
    }

    outsideZoneTimers[gameCode] = {};
  }
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
  outsideZoneTimers,
};
