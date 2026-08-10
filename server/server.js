const express = require("express");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const { randomUUID } = require("crypto");

const app = express();

app.use(cors());
app.use(express.json());

const games = {};

function getHostPlayer(game, playerId) {
  const player = game.players.find(
    (p) => p.id === playerId,
  );

  if (!player) return null;

  if (!player.host) return null;

  return player;

}

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

      outsideZoneTime: 10,
    },

    zone: {
      centerLat: lat,
      centerLng: lng,
    },

    players: [
        {
            id: randomUUID(),
            name: playerName,
            host: true,
            role: null,
            caught: false,
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
    playerId: games[gameCode].players[0].id,
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

  if (game.state !== "lobby") {
    return res.status(400).json({
      success: false,
      message: "Game already started",
    });
  }

  const player = {
    id: randomUUID(),
    name: playerName,
    host: false,
    role: null,
    caught: false,
    position: {
      lat: null,
      lng: null,
      lastUpdate: null,
    },
  };

  game.players.push(player);

  io.to(gameCode).emit(
    "lobbyUpdated",
    game,
  );

  res.json({
    success: true,
    playerId: player.id,
  });
});

app.post("/update-settings", (req, res) => {
  const { gameCode, playerId, settings } =
    req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  const host = getHostPlayer(game, playerId);

  if (!host) {
    return res.status(403).json({
      success: false,
      message: "Only the host can update settings",
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
      playerId,
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
        p => p.id === playerId
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
        id: p.id,
        name: p.name,
        role: p.role,
        caught: p.caught,
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
      playerId,
      centerLat,
      centerLng,
    } = req.body;

    const game = games[gameCode];

    if (!game) {
      return res.status(404).json({
        success: false,
      });
    }

    const host = getHostPlayer(game, playerId);

    if (!host) {
      return res.status(403).json({
        success: false,
        message: "Only the host can update zone center",
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

  const zoneCount =
    game.settings.zoneCount;

  const startRadius =
    game.settings.startRadius;

  const finalRadius =
    game.settings.finalRadius;

  const zoneWaitMs =
    game.settings.zoneWaitTime *
    60 *
    1000;

  const zoneShrinkMs =
    game.settings.zoneShrinkTime *
    60 *
    1000;

  const radiusStep =
    (startRadius - finalRadius) /
    (zoneCount - 1);

  function scheduleNextZone() {

    const currentGame =
      games[gameCode];

    if (!currentGame) return;

    if (
      currentGame.currentZone >=
      zoneCount
    ) {
      return;
    }

    currentGame.nextZoneStartsAt =
      Date.now() + zoneWaitMs;

    io.to(gameCode).emit(
      "zoneTimerUpdated",
      {
        currentZone:
          currentGame.currentZone,
        nextZoneStartsAt:
          currentGame.nextZoneStartsAt,
      },
    );

    setTimeout(() => {

      const activeGame =
        games[gameCode];

      if (!activeGame) return;

      activeGame.currentZone++;

      activeGame.zoneShrinkEndsAt =
        Date.now() +
        zoneShrinkMs;

      activeGame.currentRadius =
        Math.round(
          startRadius -
          radiusStep *
          (activeGame.currentZone - 1),
        );

      io.to(gameCode).emit(
        "zoneUpdated",
        {
          currentZone:
            activeGame.currentZone,
          radius:
            activeGame.currentRadius,
          durationMs:
            zoneShrinkMs,
          zoneShrinkEndsAt:
            activeGame.zoneShrinkEndsAt,
        },
      );

      setTimeout(() => {
        scheduleNextZone();
      }, zoneShrinkMs);

      scheduleNextZone();

    }, zoneWaitMs);
  }

  scheduleNextZone();
}


app.post("/start-game", (req, res) => {
  console.log(
    "START GAME REQUEST",
  );

  const { gameCode, playerId } = req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  const host = getHostPlayer(game, playerId);

  if (!host) {
    return res.status(403).json({
      success: false,
      message: "Only the host can start the game",
    });
  }

  if (game.state !== "lobby") {
  return res.status(400).json({
    success: false,
    message: "Game already started",
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

  setTimeout(() => {

    const currentGame =
      games[gameCode];

    if (!currentGame) return;

    if (currentGame.state !== "hidePhase") {
      return;
    }

    currentGame.state = "gameplay";

    currentGame.nextZoneStartsAt =
      Date.now() +
      currentGame.settings.zoneWaitTime *
        60 *
        1000;

    startZoneShrinking(gameCode);
    startRedZoneSystem(gameCode);

    io.to(gameCode).emit(
      "gameplayStarted",
      {
        zone: currentGame.zone,
        currentRadius:
          currentGame.currentRadius,
      },
    );

  }, game.settings.hideTime * 60 * 1000);

  io.to(gameCode).emit(
    "gameStarted",
    game,
  );

  res.json({
    success: true,
  });
});

function startRedZoneSystem(gameCode) {
  const game = games[gameCode];

  if (!game) return;

  const shiftMs =
    game.settings.redZoneShiftTime *
    1000;

    setInterval(() => {
      const activeGame =
        games[gameCode];

      if (!activeGame) return;
      
      const maxOffsetMeters = 
        activeGame.settings.startRadius;

      const angle = 
        Math.random() * 2 * Math.PI;

      const distance = 
        Math.random() * maxOffsetMeters;

      const latOffset = 
        (distance / 111320) * Math.cos(angle);

      const lngOffset = 
        (distance / (111320 * Math.cos(activeGame.zone.centerLat * (Math.PI / 180)))) * Math.sin(angle);

      const lat = 
        activeGame.zone.centerLat + latOffset;

      const lng = 
        activeGame.zone.centerLng + lngOffset;

      io.to(gameCode).emit(
        "redZoneUpdated",{
          lat, 
          lng,
          radius: activeGame.settings.redZoneRadius
        },
      ); 
    },shiftMs);
}

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

app.post("/mark-caught", (req, res) => {

  const {
    gameCode,
    playerId,
  } = req.body;

  const game = games[gameCode];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  const player =
    game.players.find(
      p => p.id === playerId
    );

  if (!player) {
    return res.status(404).json({
      success: false,
    });
  }

  player.caught = true;

  io.to(gameCode).emit(
    "playerCaught",
    {
      playerId,
      players: game.players,
    }
  );

  res.json({
    success: true,
  });

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