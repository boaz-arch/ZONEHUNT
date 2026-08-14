function registerSocketHandlers(io) {
  io.on("connection", (socket) => {
    console.log("Player connected:", socket.id);

    socket.on("joinLobby", (gameCode) => {
      socket.join(gameCode);
      console.log(`Joined lobby ${gameCode}`);
    });

    socket.on("disconnect", () => {
      console.log("Player disconnected:", socket.id);
    });
  });
}

module.exports = { registerSocketHandlers };
