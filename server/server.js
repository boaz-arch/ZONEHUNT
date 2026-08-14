const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const buildLobbyRouter = require("./routes/lobby");
const buildGameplayRouter = require("./routes/gameplay");
const buildGameInfoRouter = require("./routes/gameInfo");
const { registerSocketHandlers } = require("./sockets");

const app = express();

app.use(cors());
app.use(express.json());

const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

app.use(buildGameInfoRouter());
app.use(buildLobbyRouter(io));
app.use(buildGameplayRouter(io));

registerSocketHandlers(io);

server.listen(3000, () => {
  console.log("ZoneHunt server listening on port 3000");
});
