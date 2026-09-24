class_name Player extends Node2D
## The player's character

## How long one step takes to slide, in seconds
const STEP_DURATION: float = 0.15
## How long one running step takes to slide, in seconds
const RUN_STEP_DURATION: float = 0.06
## How long the buffer is to wait for diagonal input
const DIAGONAL_GRACE: float = 0.05
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

var grid_position: Vector2i

var _grid: FloorGrid
var _tilemap_layer: TileMapLayer
var _step_tween: Tween
# The direction of the current run, or zero when not running
var _run_direction: Vector2i = Vector2i.ZERO
# Set when a run stops, so a direction still held from it doesn't walk on by itself
var _needs_fresh_press: bool = false


func _unhandled_input(event: InputEvent) -> void:
    # A fresh direction press cancels a run
    if _run_direction == Vector2i.ZERO or not _is_direction_press(event):
        return
    _stop_run()
    get_viewport().set_input_as_handled()


## Places the player on the floor it will be walking around
func setup(floor_grid: FloorGrid, tilemap_layer: TileMapLayer, spawn: Vector2i) -> void:
    if _step_tween != null:
        _step_tween.kill()
    _stop_run()

    _grid = floor_grid
    _tilemap_layer = tilemap_layer
    grid_position = spawn
    position = _tilemap_layer.map_to_local(spawn)


## Waits for the player to choose a move they're allowed to make, then makes it
## While running, keeps stepping on its own until RunRules says to stop
func take_turn() -> void:
    # Let the last step finish sliding before choosing the next
    if _step_tween != null and _step_tween.is_running():
        await _step_tween.finished

    if _run_direction != Vector2i.ZERO:
        if RunRules.should_continue(_grid, grid_position, _run_direction):
            _step(_run_direction, RUN_STEP_DURATION)
            return
        _stop_run()

    while true:
        var direction: Vector2i = await _wait_for_direction()
        if MoveRules.can_step(_grid, grid_position, direction):
            # A direction pressed with sprint held starts a run, and that press is its first step
            if Input.is_action_pressed(&"sprint"):
                _run_direction = direction
                _step(direction, RUN_STEP_DURATION)
            else:
                _step(direction, STEP_DURATION)
            return
        # Blocked moves cost nothing, but wait a frame so holding
        # a direction into a wall doesn't freeze the game
        await get_tree().process_frame


# Returns the held direction, waiting for one if nothing is held
func _wait_for_direction() -> Vector2i:
    # After a run stops, everything has to be let go before walking again
    if _needs_fresh_press:
        while _held_direction() != Vector2i.ZERO:
            await get_tree().process_frame
        _needs_fresh_press = false

    var direction: Vector2i = _held_direction()
    if direction != Vector2i.ZERO:
        return direction # Still held from the last step, keep walking

    while direction == Vector2i.ZERO:
        await get_tree().process_frame
        direction = _held_direction()

    if direction.x == 0 or direction.y == 0:
        await get_tree().create_timer(DIAGONAL_GRACE).timeout
        var settled: Vector2i = _held_direction()
        if settled != Vector2i.ZERO:
            direction = settled

    return direction


# Moves on the grid, then slides the sprite over to match
func _step(direction: Vector2i, duration: float) -> void:
    grid_position += direction
    var target: Vector2 = _tilemap_layer.map_to_local(grid_position)
    _step_tween = create_tween()
    _step_tween.tween_property(self, "position", target, duration)


func _stop_run() -> void:
    _run_direction = Vector2i.ZERO
    _needs_fresh_press = true


# The direction currently held, including diagonals, or zero if nothing is held
func _held_direction() -> Vector2i:
    var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector2i(signi(roundi(input.x)), signi(roundi(input.y)))


func _is_direction_press(event: InputEvent) -> bool:
    for action: StringName in MOVE_ACTIONS:
        if event.is_action_pressed(action):
            return true
    return false
