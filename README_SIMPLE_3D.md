# Simple 3D Multiplayer Player Implementation

This is a basic 3D multiplayer player implementation based on the existing 2D `new_player.gd` but adapted for 3D movement.

## Files Created/Modified

### New Files
- `Scripts/new_player3d.gd` - Simple 3D player controller
- `new_player3d.tscn` - Basic 3D player scene

### Key Features

1. **First-Person Movement**:
   - WASD for movement relative to camera direction
   - Mouse look for camera rotation
   - Space for jumping
   - Escape to toggle mouse capture

2. **Multiplayer Support**:
   - Authority-based movement (only the controlling player moves their character)
   - RPC functions for teleporting and stunning
   - Proper camera setup (only the local player's camera is active)

3. **Simple Design**:
   - No complex health/experience systems
   - No combat mechanics
   - Just basic movement and multiplayer synchronization
   - Similar structure to the 2D `new_player.gd`

## Controls

- **WASD**: Move around
- **Mouse**: Look around (first-person)
- **Space**: Jump
- **Escape**: Toggle mouse capture

## How to Use

1. Start the game and join/host a lobby
2. Click "Start" button in the lobby
3. The game will load the 3D world with simple moving players

## Implementation Notes

- Uses the same multiplayer authority system as the 2D version
- Camera is positioned at head height (1.6 units up)
- Player model is a simple capsule mesh
- Gravity is applied automatically
- Movement is relative to the player's rotation (not camera)

This implementation provides a solid foundation for 3D multiplayer games while keeping the code simple and easy to understand.
