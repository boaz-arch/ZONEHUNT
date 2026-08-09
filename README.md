# ZoneHunt

A real-world multiplayer GPS hide-and-seek / battle-zone game. Players create a
game, join a lobby, pick a starting zone, hide, then play inside a shrinking
safe zone until hunters catch every hider or the clock runs out.

## Stack

- **Backend:** Node.js, Express, Socket.IO — in-memory game state, no database
- **Frontend:** Flutter, `flutter_map` (OpenStreetMap tiles), `geolocator`,
  `socket_io_client`, `shared_preferences`

## Project layout

```
server.js                    # backend: REST routes + Socket.IO events + game state
mobile/
  pubspec.yaml
  lib/
    main.dart                # app entry point
    session.dart             # save/clear session, reconnect resolver
    home_screen.dart         # create/join game
    join_screen.dart
    lobby_screen.dart        # player list, settings, zone picker, start game
    hide_phase_screen.dart   # countdown, GPS, teammate map
    gameplay_screen.dart     # shrinking zone, catch button, red zone, teammates
    full_map_screen.dart     # expanded zone preview (read-only)
    game_over_screen.dart    # win/lose screen
    zone_picker_screen.dart  # host taps map to set zone center
    settings_screen.dart     # host-only game settings sliders
    player_data.dart         # holds the local player's name
    services/
      api_service.dart       # all REST calls
      socket_service.dart    # single shared Socket.IO connection
```

## Setup

**Backend**
```bash
npm install express cors socket.io
node server.js
# listens on port 3000
```

**Frontend**
```bash
cd mobile
flutter pub get
flutter run
```

By default the app points at `http://10.10.0.10:3000` in
`lib/services/api_service.dart` and `lib/services/socket_service.dart` — change
`baseUrl` in both to match wherever you're running the server (a LAN IP for
testing on physical phones, not `localhost`).

## Client ↔ server contract

**REST**
| Route | Purpose |
|---|---|
| `POST /create-game` | Create a game, returns `gameCode` |
| `POST /join-game` | Join an existing game |
| `POST /update-settings` | Host updates game settings |
| `POST /update-zone-center` | Host sets the starting zone location |
| `POST /start-game` | Host starts the game; assigns roles, begins hide phase |
| `POST /update-position` | Player reports their current GPS position |
| `POST /mark-caught` | A hider marks themselves as caught |
| `GET /game/:code` | Full raw game object |
| `GET /game-state/:code?playerName=` | Phase, live zone radius, this player's role/caught status — used by the reconnect flow |
| `GET /positions/:code` | Current player list/positions — used to populate teammates on screen load |

**Socket.IO events (server → client)**
| Event | Purpose |
|---|---|
| `lobbyUpdated` | Player joined / settings or zone changed |
| `gameStarted` | Hide phase has begun |
| `gameplayStarted` | Hide phase ended, gameplay phase has begun (server-authoritative, doesn't rely on client timers) |
| `positionsUpdated` | Any player's GPS position changed |
| `zoneUpdated` | Safe zone is shrinking to a new radius (`{ zoneIndex, radius, durationMs }` — client animates the transition) |
| `redZoneUpdated` | Red zone moved (`{ lat, lng, radius }`) |
| `playerCaught` | A hider was marked caught |
| `gameEnded` | Game over (`{ winner: "hunters" \| "hiders" }`) |

## Features implemented

- Create/join game, real-time lobby, host-only settings and zone picking
- Hide phase: countdown, GPS tracking, safe-zone visualization, out-of-zone warning
- Gameplay phase: server-controlled shrinking zone (smooth client-side animation), distance/zone display
- Catch system: hiders self-report being caught; server validates and checks win conditions
- Red zone: server periodically repositions a red zone inside the safe zone; anyone standing in it is visible to both roles
- Role-based visibility: hunters only see hunters, hiders only see hiders (except inside the red zone)
- Reconnect: closing/reopening the app restores the correct screen, role, and zone state via `session.dart` + `/game-state`
- Back button blocked mid-game (`PopScope`) so players can't accidentally leave

## Known gaps / next steps

- **Anonymous mode labels** — letter suffixes (Hunter A/B, Hider A/B) are computed from list position, which can shift as the visible teammate list changes; worth switching to a stable per-player index.
- **Future zones** — only one shrink sequence is implemented; the "random future zones" setting exists in the UI but isn't wired to any behavior yet.
- **In-memory state** — the server has no database, so a restart wipes all active games. Fine for testing, not for production.
- **No persistence across server restarts** for reconnect — the client's saved session will look for a game that no longer exists and fall back to the home screen.
- **UI polish** — layout, typography, and branding are all functional-but-plain; see the original design notes for the full wishlist (better HUD, animations, map marker styling, etc).
