class_name PlayerControl extends Node
## Moves its entity from player input, including running

## Seconds per walking step
const STEP_DURATION: float = 0.15
## Seconds per running step
const RUN_STEP_DURATION: float = 0.06
## Seconds to wait for a second key to make a diagonal
const DIAGONAL_GRACE: float = 0.05
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

# Zero when not running
var _run_direction: Vector2i = Vector2i.ZERO
# Stops a key held from a run from walking on
var _needs_fresh_press: bool = false

@onready var _entity: Entity = get_parent() as Entity


func _ready() -> void:
    _entity.set_turn(_take_turn)
    # New floors never carry a run over
    _entity.placed.connect(_stop_run)


func _unhandled_input(event: InputEvent) -> void:
    # A fresh direction press cancels a run
    if _run_direction == Vector2i.ZERO or not _is_direction_press(event):
        return
    _stop_run()
    get_viewport().set_input_as_handled()


func _take_turn() -> void:
    await _entity.finish_slide()

    var state: FloorState = _entity.floor_state
    if _run_direction != Vector2i.ZERO:
        if RunRules.should_continue(state, _entity.grid_position, _run_direction):
            _step(_run_direction, RUN_STEP_DURATION)
            return
        _stop_run()

    while true:
        var direction: Vector2i = await _wait_for_direction()
        if MoveRules.can_step(state, _entity.grid_position, direction):
            # Sprint held starts a run
            if Input.is_action_pressed(&"sprint"):
                _run_direction = direction
                _step(direction, RUN_STEP_DURATION)
            else:
                _step(direction, STEP_DURATION)
            return
        # Wait a frame so holding into a wall doesn't freeze the game
        await get_tree().process_frame


func _wait_for_direction() -> Vector2i:
    # Everything must be let go after a run
    if _needs_fresh_press:
        while _held_direction() != Vector2i.ZERO:
            await get_tree().process_frame
        _needs_fresh_press = false

    var direction: Vector2i = _held_direction()
    if direction != Vector2i.ZERO:
        return direction # Held from the last step

    while direction == Vector2i.ZERO:
        await get_tree().process_frame
        direction = _held_direction()

    if direction.x == 0 or direction.y == 0:
        await get_tree().create_timer(DIAGONAL_GRACE).timeout
        var settled: Vector2i = _held_direction()
        if settled != Vector2i.ZERO:
            direction = settled

    return direction


# Everything else slides at the player's pace
func _step(direction: Vector2i, duration: float) -> void:
    _entity.floor_state.step_duration = duration
    _entity.step(direction, duration)


func _stop_run() -> void:
    _run_direction = Vector2i.ZERO
    _needs_fresh_press = true


func _held_direction() -> Vector2i:
    var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector2i(signi(roundi(input.x)), signi(roundi(input.y)))


func _is_direction_press(event: InputEvent) -> bool:
    for action: StringName in MOVE_ACTIONS:
        if event.is_action_pressed(action):
            return true
    return false
