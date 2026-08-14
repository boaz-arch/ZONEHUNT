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

function generateRandomZoneInside(
  centerLat,
  centerLng,
  currentRadius,
  nextRadius,
) {
  const maxOffset =
    currentRadius - nextRadius;

  const angle =
    Math.random() * 2 * Math.PI;

  const distance =
    Math.random() * maxOffset;

  const latOffset =
    (distance / 111320) * Math.cos(angle);

  const lngOffset =
    (distance / (111320 * Math.cos(centerLat * (Math.PI / 180)))) * Math.sin(angle);

  return {
    centerLat: centerLat + latOffset,
    centerLng: centerLng + lngOffset,
  };
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

      hunterCount: 1,

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


    console.log(
      game.players.map(p => ({
        name: p.name,
        id: p.id,
        role: p.role,
        lat: p.position.lat,
        lng: p.position.lng,
      }))
    );


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
    zoneCount <= 1
      ? 0
      : (startRadius - finalRadius) /
        (zoneCount - 1);

  function createPreviewZone(game) {

    if (
      game.zoneState.currentZoneNumber >=
      zoneCount
    ) {
      return false;
    }

    const nextRadius =
      Math.max(
        finalRadius,
        Math.round(
          startRadius -
          radiusStep *
          game.zoneState.currentZoneNumber
        ),
      );

    const nextZone =
      generateRandomZoneInside(
        game.zoneState.currentCenterLat,
        game.zoneState.currentCenterLng,
        game.zoneState.currentRadius,
        nextRadius,
      );

    game.zoneState.nextCenterLat =
      nextZone.centerLat;

    game.zoneState.nextCenterLng =
      nextZone.centerLng;

    game.zoneState.nextRadius =
      nextRadius;

    io.to(gameCode).emit(
      "zoneUpdated",
      {
        durationMs: 0,
        zoneState: game.zoneState,
      },
    );

    return true;
  }

  function startShrink() {

    const activeGame =
      games[gameCode];

    if (!activeGame) return;

    if (
      activeGame.zoneState.currentZoneNumber >=
      zoneCount
    ) {
      return;
    }

    activeGame.zoneState.currentZoneNumber++;

    io.to(gameCode).emit(
      "zoneTimerUpdated",
      {
        phase: "SHRINKING",
        phaseEndsAt:
          Date.now() + zoneShrinkMs,
      },
    );

    io.to(gameCode).emit(
      "zoneUpdated",
      {
        durationMs: zoneShrinkMs,
        zoneState: activeGame.zoneState,
      },
    );

    setTimeout(() => {

      const finishedGame =
        games[gameCode];

      if (!finishedGame) return;

      finishedGame.zoneState.currentCenterLat =
        finishedGame.zoneState.nextCenterLat;

      finishedGame.zoneState.currentCenterLng =
        finishedGame.zoneState.nextCenterLng;

      finishedGame.zoneState.currentRadius =
        finishedGame.zoneState.nextRadius;

      if (
        finishedGame.zoneState.currentZoneNumber >=
        zoneCount
      ) {

        finishedGame.zoneState.nextCenterLat = null;
        finishedGame.zoneState.nextCenterLng = null;
        finishedGame.zoneState.nextRadius = null;

        io.to(gameCode).emit(
          "zoneUpdated",
          {
            durationMs: 0,
            zoneState: finishedGame.zoneState,
          },
        );

        io.to(gameCode).emit(
          "zoneTimerUpdated",
          {
            phase: "FINAL ZONE",
            phaseEndsAt: null,
          },
        );

        return;
      }

      createPreviewZone(finishedGame);

      io.to(gameCode).emit(
        "zoneTimerUpdated",
        {
          phase: "NEXT SHRINK",
          phaseEndsAt:
            Date.now() + zoneWaitMs,
        },
      );

      setTimeout(
        startShrink,
        zoneWaitMs,
      );

    }, zoneShrinkMs);
  }

  //
  // Initial wait after gameplay starts
  //
  setTimeout(() => {

    const currentGame =
      games[gameCode];

    if (!currentGame) return;

    io.to(gameCode).emit(
      "zoneTimerUpdated",
      {
        phase: "NEXT SHRINK",
        phaseEndsAt:
          Date.now() + zoneWaitMs,
      },
    );

    createPreviewZone(currentGame);

    setTimeout(
      startShrink,
      zoneWaitMs,
    );

  }, zoneWaitMs);
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

  const firstNextRadius =
    Math.round(
      game.settings.startRadius -
      (
        (game.settings.startRadius -
          game.settings.finalRadius)
        /
        (game.settings.zoneCount - 1)
      ),
    );


  game.zoneState = {
    currentZoneNumber: 1,

    currentCenterLat:
        game.zone.centerLat,

    currentCenterLng:
        game.zone.centerLng,

    currentRadius:
        game.settings.startRadius,

    nextCenterLat: null,

    nextCenterLng: null,

    nextRadius: null,

    phase: "waiting",

    phaseEndsAt: null,
  };


  game.hidePhaseEndsAt =
    Date.now() +
    game.settings.hideTime *
    60 *
    1000;

  function beginGameplay(currentGame) {

    currentGame.state = "gameplay";

    currentGame.nextZoneStartsAt =
      Date.now() +
      currentGame.settings.zoneWaitTime *
      60 *
      1000;

    io.to(gameCode).emit(
      "zoneTimerUpdated",
      {
        phase: "NEXT SHRINK",
        phaseEndsAt: null,
      },
    );

    startZoneShrinking(gameCode);
    startRedZoneSystem(gameCode);

    io.to(gameCode).emit(
      "gameplayStarted",
      {
        zone: {
          centerLat:
            currentGame.zoneState.currentCenterLat,
          centerLng:
            currentGame.zoneState.currentCenterLng,
        },
        currentRadius:
          currentGame.zoneState.currentRadius,
        zoneState:
          currentGame.zoneState,
      },
    );
  }

  const hideMs =
    game.settings.hideTime *
    60 *
    1000;

  if (hideMs <= 0) {

    beginGameplay(game);

  } else {

    setTimeout(() => {

      const currentGame =
        games[gameCode];

      if (!currentGame) return;

      if (
        currentGame.state !== "hidePhase"
      ) {
        return;
      }

      beginGameplay(currentGame);

    }, hideMs);

  }   

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
      "redZoneUpdated", {
      lat,
      lng,
      radius: activeGame.settings.redZoneRadius
    },
    );
  }, shiftMs);
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
      zoneState:
        game.zoneState,
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

  const aliveHiders =
    game.players.filter(
      p =>
        p.role === "hider" &&
        !p.caught,
    );

  if (aliveHiders.length === 0) {

    game.state = "ended";

    io.to(gameCode).emit(
      "gameEnded",
      {
        winner: "Hunters",
      },
    );
  }

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


app.get("/test-state/:code", (req, res) => {
  const game =
    games[req.params.code];

  if (!game) {
    return res.status(404).json({
      success: false,
    });
  }

  res.json(game.zoneState);
});

console.log(
  generateRandomZoneInside(
    31.7683,
    35.2137,
    1000,
    700,
  ),
);

server.listen(3000, () => {
  console.log(
    "ZoneHunt server listening on port 3000",
  );
});