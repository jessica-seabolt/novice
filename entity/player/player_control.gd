class_name PlayerControl extends Node
## Moves its entity from player input

## Seconds per walking step
const STEP_DURATION: float = 0.15
## Seconds per running step
const RUN_STEP_DURATION: float = 0.03
## Seconds to wait for a second key to make a diagonal
const DIAGONAL_GRACE: float = 0.05
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]
## One per known spell
const SLOT_ACTIONS: Array[StringName] = [&"spell_1", &"spell_2", &"spell_3", &"spell_4"]

# Zero when not running
var _run_direction: Vector2i = Vector2i.ZERO
# Stops a key held from a run from walking on
var _needs_fresh_press: bool = false
# Entities the last step landed next to
var _new_neighbours: Array[Entity] = []
# Set when the stick returns to centre during a run
var _stick_centred: bool = false
# A cast or item use chosen outside the turn, done when the turn comes
var _requested_action: Callable
# Stepping onto an item ends a run
var _landed_on_item: bool = false
# Only true while its turn waits on the player; other input is ignored
var _awaiting_input: bool = false
# Entities in view at the start of the last turn
var _seen: Array[Entity] = []

@onready var _entity: Entity = get_parent() as Entity
@onready var _spellbook: Spellbook = Spellbook.of(_entity)
@onready var _inventory: Inventory = Inventory.of(_entity)


## Null if the entity isn't player-controlled
static func of(entity: Entity) -> PlayerControl:
    return entity.get_node_or_null("PlayerControl") as PlayerControl


func _ready() -> void:
    _entity.set_turn(_take_turn)
    # New floors never carry a run over
    _entity.placed.connect(_stop_run)
    Stats.of(_entity).damaged.connect(_on_damaged)
    _spellbook.requested.connect(_request_spell)
    _inventory.requested.connect(_request_item)


func _unhandled_input(event: InputEvent) -> void:
    var spell: Spell = _spell_for(event)
    if spell != null:
        if _awaiting_input:
            _spellbook.request(spell)
        get_viewport().set_input_as_handled()
        return
    # A fresh direction press cancels a run, even between turns
    if _run_direction == Vector2i.ZERO:
        return
    if event is InputEventJoypadMotion:
        if not _stick_cancels_run():
            return
    elif not _is_direction_press(event):
        return
    _stop_run()
    get_viewport().set_input_as_handled()


func is_awaiting_input() -> bool:
    return _awaiting_input


func _take_turn() -> void:
    await _entity.finish_slide()

    var state: FloorState = _entity.floor_state
    var sighted: bool = _update_seen(state)
    if _run_direction != Vector2i.ZERO:
        var keep_running: bool = (
            not sighted
            and not _landed_on_item
            and not _still_next_to_new_neighbour()
            and RunRules.should_continue(state, _entity.grid_position, _run_direction)
        )
        if keep_running:
            _step(_run_direction, RUN_STEP_DURATION)
            return
        _stop_run()

    _awaiting_input = true
    await _act_on_input(state)
    _awaiting_input = false


func _act_on_input(state: FloorState) -> void:
    while true:
        var direction: Vector2i = await _wait_for_direction()
        if _requested_action.is_valid():
            await _perform_requested()
            return
        # Turning in place is free
        if Input.is_action_pressed(&"aim"):
            _entity.face(direction)
            await get_tree().process_frame
            continue
        if MoveRules.can_step(state, _entity.grid_position, direction):
            # Sprint held starts a run
            if Input.is_action_pressed(&"sprint"):
                _run_direction = direction
                _stick_centred = false
                _step(direction, RUN_STEP_DURATION)
            else:
                _step(direction, STEP_DURATION)
            return
        _entity.face(direction)
        # Wait a frame so holding into a wall doesn't freeze the game
        await get_tree().process_frame


func _wait_for_direction() -> Vector2i:
    # After a run, the direction or sprint must be let go
    if _needs_fresh_press:
        var sprint_held: bool = Input.is_action_pressed(&"sprint")
        while _held_direction() != Vector2i.ZERO and not Input.is_action_pressed(&"aim"):
            if sprint_held and not Input.is_action_pressed(&"sprint"):
                break
            sprint_held = Input.is_action_pressed(&"sprint")
            if _requested_action.is_valid():
                return Vector2i.ZERO
            await get_tree().process_frame
        _needs_fresh_press = false

    var direction: Vector2i = _held_direction()
    if direction != Vector2i.ZERO:
        return direction # Held from the last step

    while direction == Vector2i.ZERO:
        if _requested_action.is_valid():
            return Vector2i.ZERO
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
    var state: FloorState = _entity.floor_state
    # Entities walking up to the player don't count
    _new_neighbours = RunRules.new_neighbours(state, _entity.grid_position, direction)
    _landed_on_item = state.items.has_item(_entity.grid_position + direction)
    state.step_duration = duration
    _entity.step(direction, duration)


func _request_spell(spell: Spell) -> void:
    _requested_action = _spellbook.cast.bind(spell)


func _request_item(stack: ItemStack, action: Inventory.Action) -> void:
    _requested_action = _act_on_item.bind(stack, action)


func _perform_requested() -> void:
    var action: Callable = _requested_action
    _requested_action = Callable()
    if _run_direction != Vector2i.ZERO:
        _stop_run()
    _entity.floor_state.step_duration = STEP_DURATION
    await action.call()


func _act_on_item(stack: ItemStack, action: Inventory.Action) -> void:
    await _entity.floor_state.wait_for_slides()
    _entity.hold(Inventory.ACTION_DURATION)
    match action:
        Inventory.Action.USE:
            _inventory.use(stack)
        Inventory.Action.DROP:
            _inventory.drop(stack)


# Whether anything came into view since the last turn
func _update_seen(state: FloorState) -> bool:
    var seen: Array[Entity] = []
    var sighted: bool = false
    for entity: Entity in state.occupancy.get_entities():
        var visible: bool = Sight.can_see(state, _entity.grid_position, entity.grid_position)
        if entity == _entity or not visible:
            continue
        seen.append(entity)
        sighted = sighted or entity not in _seen
    _seen = seen
    return sighted


# Ones that have since moved away, like a mob being chased, don't stop the run
func _still_next_to_new_neighbour() -> bool:
    for entity: Entity in _new_neighbours:
        var here: Vector2i = _entity.grid_position
        if is_instance_valid(entity) and RunRules.is_adjacent(entity.grid_position, here):
            return true
    return false


func _on_damaged(_amount: int) -> void:
    if _run_direction != Vector2i.ZERO:
        _stop_run()


func _stop_run() -> void:
    _run_direction = Vector2i.ZERO
    _needs_fresh_press = true


func _held_direction() -> Vector2i:
    if get_tree().paused:
        return Vector2i.ZERO
    var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    return Vector2i(signi(roundi(input.x)), signi(roundi(input.y)))


# Stick wobble only cancels past 90 degrees, or after recentring
func _stick_cancels_run() -> bool:
    var held: Vector2i = _held_direction()
    if held == Vector2i.ZERO:
        _stick_centred = true
        return false
    return _stick_centred or held.x * _run_direction.x + held.y * _run_direction.y <= 0


# Null if the event isn't a cast; slots on a controller need the modifier held
func _spell_for(event: InputEvent) -> Spell:
    if event.is_action_pressed(&"basic_spell"):
        return Spellbook.BASIC
    for i: int in range(SLOT_ACTIONS.size()):
        if not event.is_action_pressed(SLOT_ACTIONS[i]):
            continue
        if event is InputEventJoypadButton and not Input.is_action_pressed(&"spell_modifier"):
            return null
        return _spellbook.spells[i] if i < _spellbook.spells.size() else null
    return null


func _is_direction_press(event: InputEvent) -> bool:
    for action: StringName in MOVE_ACTIONS:
        if event.is_action_pressed(action):
            return true
    return false
