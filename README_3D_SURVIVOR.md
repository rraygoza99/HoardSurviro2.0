# 3D Hoard Survivor Game - Multiplayer Implementation

This is a 3D multiplayer hoard survivor game built on top of the existing Godot multiplayer bomber game framework. The game uses Steam multiplayer for networking.

## Features Implemented

### Player System (`Scripts/player3d.gd`)
- **3D First-Person Movement**: WASD movement with mouse look
- **Health System**: 100 HP with damage, healing, and invincibility frames
- **Level/Experience System**: Gain XP to level up
- **Multiplayer Authority**: Proper client-server authority handling
- **Combat System**: Basic ranged attacks using raycasting

### Enemy System (`Scripts/enemy3d.gd`)
- **AI Behavior**: Enemies chase the nearest player
- **Different Enemy Types**: Basic, Fast, Tank, and Boss zombies
- **Health/Damage System**: Enemies can take damage and die
- **Multiplayer Sync**: Server-authoritative enemy behavior

### Game Management (`survivor_game_manager.gd`)
- **Wave System**: Progressive waves with increasing difficulty
- **Enemy Spawning**: Automatic enemy spawning around the map
- **Experience Rewards**: Players gain XP for kills and wave completion
- **Game State Management**: Tracks waves, enemies, and player progress

### UI System (`Scripts/game_hud.gd`)
- **Health Bar**: Shows current player health
- **Level/XP Display**: Shows player level and experience progress
- **Wave Information**: Current wave, enemies remaining, time left
- **Crosshair**: Simple crosshair for aiming

## Key Files

### Scripts
- `Scripts/player3d.gd` - Main 3D player controller
- `Scripts/enemy3d.gd` - Enemy AI and behavior
- `Scripts/game_hud.gd` - Game UI management
- `survivor_game_manager.gd` - Wave and game state management

### Scenes
- `player3d.tscn` - 3D player scene
- `enemy3d.tscn` - Basic enemy scene
- `world3d.tscn` - 3D game world with spawn points
- `game_hud.tscn` - Game UI overlay

### Core Systems
- `gamestate.gd` - Extended with 3D game support
- `project.godot` - Updated with new input actions

## How to Test

1. **Setup Steam**: The game uses Steam multiplayer, so you need:
   - Steam running
   - Valid Steam App ID (currently set to 3965800)
   - SteamAPI files in the addons folder

2. **Start Game**:
   - Run the project
   - Host a lobby or join an existing one
   - Use the "Start 3D Game" button (you'll need to add this to the lobby UI)

3. **Controls**:
   - **WASD**: Move
   - **Mouse**: Look around
   - **Space**: Attack
   - **Escape**: Toggle mouse capture

## Current State

The basic framework is complete with:
- ✅ 3D multiplayer player movement
- ✅ Enemy spawning and AI
- ✅ Wave-based gameplay
- ✅ Health and experience systems
- ✅ Basic combat (raycast attacks)
- ✅ UI for game information

## TODO - Next Steps

1. **Enhance Combat**:
   - Add different weapon types
   - Implement projectiles
   - Add weapon upgrades

2. **Improve Enemies**:
   - Add more enemy types
   - Better AI behaviors
   - Visual and sound effects

3. **Progression System**:
   - Skill trees and upgrades
   - Equipment/items system
   - Power-ups and collectibles

4. **Polish**:
   - Particle effects
   - Sound design
   - Better 3D models and animations
   - Death/respawn system

5. **UI Improvements**:
   - Main menu integration
   - In-game settings
   - End game statistics

## Technical Notes

- The game maintains compatibility with the original 2D bomber game
- Uses the existing Steam multiplayer infrastructure
- Server-authoritative for enemy behavior and combat
- Client prediction for smooth movement
- All RPCs are properly secured with authority checks

## Usage

To start a 3D survivor game session:
1. Call `gamestate.begin_game_3d()` instead of `gamestate.begin_game()`
2. The survivor game manager will automatically start wave progression
3. Players spawn and can immediately start fighting enemies

The implementation is designed to be easily extensible for additional features like weapons, skills, and more complex enemy behaviors.
