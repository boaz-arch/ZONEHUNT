const gameStore = require("../store/gameStore");

function registerSocketHandlers(io) {
  io.on("connection", (socket) => {
    console.log("Player connected:", socket.id);
 
    socket.on("joinLobby", (data) => {

      const {
        gameCode,
        playerId,
      } = data;

      socket.join(gameCode);

      socket.gameCode = gameCode;
      socket.playerId = playerId;

      gameStore.clearReconnectTimer(
        playerId,
      );

      const game = gameStore.getGame(gameCode);

      if (game) {

        const player =
          game.players.find(
            (p) => p.id === playerId,
          );

        if (player) {

          const wasDisconnected =
            player.disconnected === true;

          player.disconnected = false;

          if (wasDisconnected) {

            console.log(
              "Player reconnected:",
              playerId,
            );

            io.to(gameCode).emit(
              "playerReconnected",
              {
                playerId,
              },
            );
          }
        }
      }

      console.log(
        `Joined lobby ${gameCode} player ${playerId}`,
      );

    });
 
    socket.on("disconnect", () => {
      console.log(
        "Player disconnected:",
        socket.id,
      );

      if (
        !socket.playerId ||
        !socket.gameCode
      ) {
        return;
      }

      const playerId =
        socket.playerId;

      const gameCode =
        socket.gameCode;

      const game =
        gameStore.getGame(
          gameCode,
        );

      if (!game) {
        return;
      }

      const player =
        game.players.find(
          (p) =>
            p.id === playerId,
        );

      if (!player) {
        return;
      }

      player.disconnected = true;

      const timer =
        setTimeout(() => {

          const latestGame =
            gameStore.getGame(
              gameCode,
            );

          if (!latestGame) {
            return;
          }

          const latestPlayer =
            latestGame.players.find(
              (p) =>
                p.id === playerId,
            );

          if (
            !latestPlayer ||
            latestPlayer.disconnected !== true
          ) {
            return;
          }

          console.log(
            "Reconnect window expired:",
            playerId,
          );

          const playerIndex =
            latestGame.players.findIndex(
              (p) => p.id === playerId,
            );

          if (playerIndex === -1) {
            return;
          }

          const expiredPlayer =
            latestGame.players[playerIndex];

          if (!expiredPlayer.host) {
            latestGame.players.splice(
              playerIndex,
              1,
            );

            console.log(
              "Removed player:",
              playerId,
            );

            io.to(gameCode).emit(
              "lobbyUpdated",
              latestGame,
            );
          }

          if (expiredPlayer.host) {
            const newHost =
              latestGame.players.find(
                (p) =>
                  p.id !== playerId,
              );

            if (!newHost) {

              console.log(
                "No players remain. Deleting game:",
                gameCode,
              );

              gameStore.deleteGame(
                gameCode,
              );

              return;
            }

            newHost.host = true;

            latestGame.players.splice(
              playerIndex,
              1,
            );

            console.log(
              "Transferred host to:",
              newHost.id,
            );

            io.to(gameCode).emit(
              "lobbyUpdated",
              latestGame,
            );
          }

        }, 60000);

      gameStore.registerReconnectTimer(
        playerId,
        timer,
      );
    });
  });
}
 
module.exports = { registerSocketHandlers };
 
