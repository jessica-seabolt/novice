class_name Entity extends Node2D
## Anything that stands on a floor and takes turns

signal placed

var grid_position: Vector2i
var facing: Vector2i = Vector2i.DOWN
var floor_state: FloorState

var _tilemap_layer: TileMapLayer
var _step_tween: Tween
# Where the current slide ends
var _slide_target: Vector2
var _turn: Callable


## Places the entity, cancelling any slide in progress
func setup(state: FloorState, tilemap_layer: TileMapLayer, spawn: Vector2i) -> void:
    if _step_tween != null:
        _step_tween.kill()

    floor_state = state
    _tilemap_layer = tilemap_layer
    grid_position = spawn
    position = _tilemap_layer.map_to_local(spawn)
    floor_state.occupancy.place(self, spawn)
    placed.emit()


## Set by the component that controls this entity
func set_turn(turn: Callable) -> void:
    _turn = turn


func take_turn() -> void:
    await _turn.call()


## Moves on the grid at once, then slides the sprite to match
func step(direction: Vector2i, duration: float) -> void:
    var to: Vector2i = grid_position + direction
    floor_state.occupancy.move(self, grid_position, to)
    grid_position = to
    facing = direction

    # Finish an almost-done slide rather than cutting its last frame
    if _step_tween != null and _step_tween.is_running():
        _step_tween.kill()
        position = _slide_target

    _slide_target = _tilemap_layer.map_to_local(grid_position)
    _step_tween = create_tween()
    _step_tween.tween_property(self, "position", _slide_target, duration)


func face(direction: Vector2i) -> void:
    facing = direction


## A tile's area in the same space as the entity's position
func tile_rect(p: Vector2i) -> Rect2:
    var size: Vector2 = Vector2(_tilemap_layer.tile_set.tile_size)
    return Rect2(_tilemap_layer.map_to_local(p) - size / 2.0, size)


## Waits for the current slide to end
func finish_slide() -> void:
    if _step_tween != null and _step_tween.is_running():
        await _step_tween.finished
