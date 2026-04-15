# TRON Arcade (1982) — Game Mechanics Reference

## Original Cabinet

| Field | Value |
|-------|-------|
| Developer | Bally Midway |
| Year | 1982 |
| Hardware | Z80 CPU, custom video |
| Display | Standard raster, 19" monitor |
| Input | 8-way joystick + trigger + spinner dial |
| Games | 4 sub-games per credit |

The player chooses which sub-game to play. Completing all four advances to the next difficulty level. Each level increases speed and adds enemies.

## Light Cycles

**Mechanics:**
- Two players (or player vs AI) on a grid
- Each cycle moves continuously in its current direction
- Turning leaves a permanent wall behind the cycle
- Collision with any wall, trail, or boundary = death
- Last cycle alive wins the round

**Grid:** Discrete grid, movement in 4 directions (up/down/left/right). No diagonal. Speed increases with difficulty level.

**AI behavior (original):** The AI avoids walls with ~2 cells lookahead and attempts to cut off the player's escape routes. Higher difficulty = deeper lookahead.

## MCP Cone

**Mechanics:**
- Concentric rotating barriers (rings) with gaps
- Player fires projectiles through gaps to break barriers
- Each barrier rotates at its own speed
- Breaking through all barriers reaches the MCP core
- Getting hit by a barrier segment = death

**Pattern:** Barriers rotate in alternating directions. Gap positions shift per rotation. Player must time shots to pass through aligned gaps.

## Battle Tanks

**Mechanics:**
- Top-down maze, player tank vs enemy tank(s)
- Tanks move on the grid, can aim and fire independently
- Projectiles ricochet off walls (1 bounce in original, some versions allow 2)
- Direct hit = kill
- Recognizer enemies patrol on later levels

**Maze:** Fixed layouts per level, no procedural generation in original. Walls are single-thickness grid lines.

**AI:** Enemy tanks pursue player through the maze, fire when line-of-sight is clear. Higher difficulty = faster movement, faster projectiles.

## Grid Bugs

**Mechanics:**
- Player moves along grid lines (intersections are nodes)
- Grid bugs spawn and move toward the player via grid paths
- Player must reach the I/O Tower (goal) to complete the level
- Contact with a bug = death
- Bonus points for clearing bugs

**Grid:** Network of horizontal and vertical lines. Movement is constrained to the lines — no free movement. This is topologically a graph traversal game.

## Visual Style

All four games share the neon-on-black aesthetic:
- Black background
- Bright colored lines for all game elements
- No filled polygons in the original (pure vector look on raster display)
- Player elements in cyan/blue, enemies in red/orange
- Grid/structure in dim blue

This visual constraint is both the art style and the technical simplification — every visual element is a line or sequence of lines. No textures, no sprites, no alpha blending.
