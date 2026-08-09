const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const app = express();

app.use(cors());
app.use(express.json());

const games = {};

function generateGameCode(length = 6) {
  const chars =
  // ABCDEFGHJKLMNPQRSTUVWXYZ23456789
  // ABCDEFGHIJKLMNOPQRSTUVWXYZ
    "1234567890";

  let code = "";

  for (let i = 0; i < length; i++) {
    code += chars[
      Math.floor(
        Math.random() * chars.length
      )
    ];
  }

  return code;
}

function assignRoles(game) {
  game.players.forEach((player) => {
    player.role = "hider";
  });

  const shuffledPlayers = [
    ...game.players,
  ].sort(() => Math.random() - 0.5);

  const hunterCount = Math.min(
    game.settings.hunterCount,
    game.players.length - 1,
  );

  for (
    let i = 0;
    i < hunterCount;
    i++
  ) {
    if (shuffledPlayers[i]) {
      shuffledPlayers[i].role =
        "hunter";
    }
  }
}

app.get("/", (req, res) => {
  res.send("ZoneHunt API Online");
});

app.post("/create-game", (req, res) => {
    const {
        playerName,
        lat,
        lng,
    } = req.body;


  const gameCode = generateGameCode();

  games[gameCode] = {
    gameCode,

    state: "lobby",

    settings: {
      gameDuration: 60,
      hideTime: 5,

      hunterCount: 2,

      zoneCount: 5,

      startRadius: 1000,
      finalRadius: 100,

      zoneWaitTime: 5,
      zoneShrinkTime: 3,

      redZoneRadius: 50,
      redZoneShiftTime: 120,

      anonymousMode: false,
      randomFutureZones: true,
    },

    zone: {
      centerLat: lat,
      centerLng: lng,
    },

    players: [
        {
            name: playerName,
            host: true,

            role: null,

            position: {
              lat: null,
              lng: null,
              lastUpdate: null,
            },
        },
    ],
};

  res.json({
    success: true,
    gameCode,
  });
});

app.post("/join-game", (req, res) => {
  const { gameCode, playerName } =
    req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
      message: "Game not found",
    });
  }

    game.players.push({
        name: playerName,
        host: false,

        role: null,

        position: {
            lat: null,
            lng: null,
            lastUpdate: null,
        },
    });

  io.to(gameCode).emit(
    "lobbyUpdated",
    game,
  );

  res.json({
    success: true,
  });
});

app.post("/update-settings", (req, res) => {
  const { gameCode, settings } =
    req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  game.settings = settings;

  io.to(gameCode).emit(
    "lobbyUpdated",
    game,
  );

  res.json({
    success: true,
  });
});

app.post(
  "/update-position",
  (req, res) => {

    const {
      gameCode,
      playerName,
      lat,
      lng,
    } = req.body;

    const game = games[gameCode];

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    const player =
      game.players.find(
        (p) => p.name === playerName,
      );

    if (!player) {
      return res.status(404).json({
        success: false,
      });
    }

    player.position = {
      lat,
      lng,
      lastUpdate: Date.now(),
    };

    io.to(gameCode).emit(
      "positionsUpdated",
      game.players,
    );

    res.json({
      success: true,
    });
  },
);

app.get(
  "/positions/:code",
  (req, res) => {

    const game =
      games[req.params.code];

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    res.json(
      game.players.map((p) => ({
        name: p.name,
        role: p.role,
        position: p.position,
      })),
    );
  },
);

app.post(
  "/update-zone-center",
  (req, res) => {
    const {
      gameCode,
      centerLat,
      centerLng,
    } = req.body;

    const game = games[gameCode];

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    game.zone = {
      centerLat,
      centerLng,
    };

    io.to(gameCode).emit(
      "lobbyUpdated",
      game,
    );

    res.json({
      success: true,
    });
  },
);

function startZoneShrinking(gameCode) {
  const game = games[gameCode];

  if (!game) return;

  const zoneCount = game.settings.zoneCount;
  const startRadius = game.settings.startRadius;
  const finalRadius = game.settings.finalRadius;

  const radiusStep =
      (startRadius - finalRadius) /
      (zoneCount - 1);

  let currentZone = 1;

  setInterval(() => {

    if (!games[gameCode]) return;

    if (currentZone >= zoneCount) return;

    currentZone++;

    game.currentZone = currentZone;

    game.currentRadius =
        Math.round(
          startRadius -
          radiusStep *
          (currentZone - 1)
        );

    io.to(gameCode).emit(
      "zoneUpdated",
      {
        currentZone: game.currentZone,
        currentRadius: game.currentRadius,
      }
    );

  }, 30000);
}

app.post("/start-game", (req, res) => {
  console.log(
    "START GAME REQUEST",
  );

  const { gameCode } = req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  assignRoles(game);

  game.state = "hidePhase";

  game.currentZone = 1;

  game.currentRadius =
  game.settings.startRadius;

  game.hidePhaseEndsAt =
    Date.now() +
    game.settings.hideTime *
      60 *
      1000;

  startZoneShrinking(gameCode);    

  io.to(gameCode).emit(
    "gameStarted",
    game,
  );

  res.json({
    success: true,
  });
});

app.get("/game/:code", (req, res) => {
  const game = games[req.params.code];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  res.json(game);
});

app.get(
  "/game-state/:code",
  (req, res) => {
    const game =
      games[req.params.code];

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    res.json({
      state: game.state,
      hidePhaseEndsAt:
        game.hidePhaseEndsAt,
      players: game.players,
      settings: game.settings,
      zone: game.zone,
    });
  },
);

app.get("/games", (req, res) => {
  res.json(games);
});

const server =
  http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: "*",
  },
});

io.on("connection", (socket) => {
  console.log(
    "Player connected:",
    socket.id,
  );

  socket.on(
    "joinLobby",
    (gameCode) => {
      socket.join(gameCode);

      console.log(
        `Joined lobby ${gameCode}`,
      );
    },
  );

  socket.on("disconnect", () => {
    console.log(
      "Player disconnected:",
      socket.id,
    );
  });
});

server.listen(3000, () => {
  console.log(
    "ZoneHunt server listening on port 3000",
  );
});