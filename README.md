# ZoneHunt

ZoneHunt is a real-world multiplayer GPS hide-and-seek battle game inspired by battle royale games such as PUBG.

Players create or join a game, gather in a lobby, select a starting zone, hide during a preparation phase, and then compete inside a shrinking safe zone while moving in the real world. Live GPS positioning, real-time synchronization, and dynamic zone mechanics create a unique outdoor multiplayer experience.

---

# Features

## Multiplayer Lobby System

- Create private games
- Join games with a game code
- Real-time lobby updates
- Host controls
- Live player list
- Interactive map preview
- Custom game settings

---

## Role-Based Gameplay

Players are randomly assigned one of two roles:

### Hunters

- Work together with other hunters
- Search for hiders
- Eliminate all hiders before time runs out

### Hiders

- Hide within the safe zone
- Avoid detection
- Survive until the game timer expires

---

# Game Flow

## 1. Create or Join

Players can create a new game or join an existing game using a game code.

## 2. Lobby

The lobby allows players to:

- View connected players
- Configure game settings
- Select the first safe zone
- Preview the game area
- Wait for all players to join

## 3. Hide Phase

When the game starts:

- Roles are assigned
- GPS tracking begins
- Team positions become visible
- Players move to their starting locations
- Safe zone boundaries are displayed

## 4. Gameplay Phase

After the hide timer expires:

- The match becomes active
- Players move in the real world
- Position updates occur in real time
- Team tracking remains active
- Zone warnings are displayed

---

# Safe Zone System

ZoneHunt uses a battle royale style shrinking safe zone.

The server controls all zone progression to ensure every player sees the same game state.

Features include:

- Server-authoritative zones
- Real-time synchronization
- Multiple shrinking stages
- Final zone showdown

As the match progresses, the safe zone becomes smaller and forces players closer together.

---

# Blue Storm

Everything outside the safe zone is covered by a blue storm effect.

The blue storm serves as a visual indicator of the dangerous area outside the current zone.

Features:

- Blue battlefield boundary
- Dynamic updates during zone shrinking
- Clear distinction between safe and unsafe areas
- Battle royale style visual presentation

---

# Red Zone

The Red Zone is a moving danger area.

Features:

- Periodically changes location
- Moves around the map throughout the match
- Creates pressure on players to reposition

## Exposure Mechanic

Players located inside the Red Zone become exposed.

Exposed players are visible to all players regardless of team.

This creates temporary risk and encourages movement.

---

# Team Visibility

Visibility depends on role.

### Hunters Can See

- Other hunters
- Exposed players inside the Red Zone

### Hiders Can See

- Other hiders
- Exposed players inside the Red Zone

Enemy players remain hidden unless exposed.

---

# Anonymous Mode

Anonymous Mode hides player identities.

Instead of player names:

```text
Boaz
John
Alex
```

players are displayed as:

```text
Hunter A
Hunter B
Hunter C

Hider A
Hider B
Hider C
```

This removes identity-based advantages and increases strategy.

---

# GPS Tracking

ZoneHunt uses live GPS positioning.

Features:

- Real-time location tracking
- Live teammate updates
- Distance from zone center
- Out-of-zone detection
- Movement synchronization across all devices

---

# Catch System

Hiders can mark themselves as caught during gameplay.

When a hider is caught:

- Their status is updated for all players
- They are removed from active play
- Win conditions are re-evaluated

Future versions will include distance-based hunter validation.

---

# Win Conditions

## Hunters Win

All hiders are caught.

## Hiders Win

The game timer expires and at least one hider remains uncaught.

---

# Reconnect System

ZoneHunt supports reconnecting to active games.

If a player refreshes or reopens the app:

- The active game is restored
- Current phase is restored
- Role information is restored
- Gameplay continues seamlessly

Supported reconnect phases:

- Lobby
- Hide Phase
- Gameplay

---

# Game Settings

Hosts can configure:

| Setting | Description |
|----------|-------------|
| Game Duration | Total match length |
| Hide Time | Preparation duration |
| Hunter Count | Number of hunters |
| Zone Count | Number of shrinking zones |
| Start Radius | Initial safe-zone size |
| Final Radius | Final safe-zone size |
| Zone Wait Time | Time before shrink begins |
| Zone Shrink Time | Duration of 