class_name Entity extends Node2D
## Anything that stands on a floor and takes turns

signal placed

var grid_position: Vector2i
var floor_state: FloorState

var _tilemap_layer: TileMapLayer
var _step_tween: Tween
# Where the current slide ends
var _slide_target: Vector2
var _turn: Callable


## Places the entity on a floor, cancelling any slide still in progress
func setup(state: FloorState, tilemap_layer: TileMapLayer, spawn: Vector2i) -> void:
    if _step_tween != null:
        _step_tween.kill()

    floor_state = state
    _tilemap_layer = tilemap_layer
    grid_position = spawn
    position = _tilemap_layer.map_to_local(spawn)
    floor_state.occupancy.place(self, spawn)
    placed.emit()


## Gives the entity the function that decides and makes its move each turn
func set_turn(turn: Callable) -> void:
    _turn = turn


func take_turn() -> void:
    await _turn.call()


## Moves one tile on the grid right away, then slides the sprite over to match
func step(direction: Vector2i, duration: float) -> void:
    var to: Vector2i = grid_position + direction
    floor_state.occupancy.move(self, grid_position, to)
    grid_position = to

    # A slide that hasn't quite finished is completed rather than cut short, so its last frame
    # of movement isn't lost
    if _step_tween != null and _step_tween.is_running():
        _step_tween.kill()
        position = _slide_target

    _slide_target = _tilemap_layer.map_to_local(grid_position)
    _step_tween = create_tween()
    _step_tween.tween_property(self, "position", _slide_target, duration)


## Waits until the last step has finished sliding, if it hasn't already
func finish_slide() -> void:
    if _step_tween != null and _step_tween.is_running():
        await _step_tween.finished
