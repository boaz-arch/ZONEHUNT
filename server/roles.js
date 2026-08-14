function generateGameCode(length = 6) {
  const chars = "1234567890";

  let code = "";

  for (let i = 0; i < length; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }

  return code;
}

function assignRoles(game) {
  game.players.forEach((player) => {
    player.role = "hider";
  });

  const shuffledPlayers = [...game.players].sort(
    () => Math.random() - 0.5,
  );

  const hunterCount = Math.min(
    game.settings.hunterCount,
    game.players.length - 1,
  );

  for (let i = 0; i < hunterCount; i++) {
    if (shuffledPlayers[i]) {
      shuffledPlayers[i].role = "hunter";
    }
  }
}

module.exports = {
  generateGameCode,
  assignRoles,
};
