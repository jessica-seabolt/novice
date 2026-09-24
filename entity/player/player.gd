class_name Player extends Node2D
## The player's character, walking the floor one tile per turn

## How long one step takes to slide, in seconds
const STEP_DURATION: float = 0.15
## How long a freshly pressed direction waits for a second key, so two keys make a diagonal
const DIAGONAL_GRACE: float = 0.05

var grid_position: Vector2i

var _grid: FloorGrid
var _tilemap_layer: TileMapLayer
var _step_tween: Tween


## Places the player on the floor it will be walking around
func setup(floor_grid: FloorGrid, tilemap_layer: TileMapLayer, spawn: Vector2i) -> void:
    _grid = floor_grid
    _tilemap_layer = tilemap_layer
    grid_position = spawn
    position = _tilemap_layer.map_to_local(spawn)


## Waits for the player to choose a move they're allowed to make, then makes it
func take_turn() -> void:
    # Let the last step finish sliding before choosing the next
    if _step_tween != null and _step_tween.is_running():
        await _step_tween.finished

    while true:
        var direction: Vector2i = await _wait_for_direction()
        if MoveRules.can_step(_grid, grid_position, direction):
            _step(direction)
            return
        # Blocked moves cost nothing, but wait a frame so that holding
        # a direction into a wall doesn't freeze the game
        await get_tree().process_frame


# Returns the held direction, waiting for one if nothing is held
# A fresh press waits a moment longer, in case a second key is on its way to make a diagonal
func _wait_for_direction() -> Vector2i:
    var direction: Vector2i = _held_direction()
    if direction != Vector2i.ZERO:
        return direction # Still held from the last step, so keep walking without delay

    while direction == Vector2i.ZERO:
        await get_tree().process_frame
        direction = _held_direction()

    if direction.x == 0 or direction.y == 0:
        await get_tree().create_timer(DIAGONAL_GRACE).timeout
        var settled: Vector2i = _held_direction()
        if settled != Vector2i.ZERO:
            direction = settled

    return direction


# Moves on the grid right away, then slides the sprite over to match
func _step(direction: Vector2i) -> void:
    grid_position += direction
    var target: Vector2 = _tilemap_layer.map_to_local(grid_position)
    _step_tween = create_tween()
    _step_tween.tween_property(self, "position", target, STEP_DURATION)


# The direction currently held, including diagonals, or zero if nothing is held
func _held_direction() -> Vector2i:
    var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector2i(signi(roundi(input.x)), signi(roundi(input.y)))
