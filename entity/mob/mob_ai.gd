class_name MobAI extends Node
## Wanders, pursues and attacks the player on sight, then searches where they were last seen

enum State {
    WANDER,
    PURSUE,
    SEARCH,
}

## Extra turns a search gets beyond its planned path before giving up
const SEARCH_SLACK: int = 5
## Extra tiles a detour around a blocking entity may add
const DETOUR_LIMIT: int = 4
const NO_ROOM: int = -1

var _state: MobAI.State = MobAI.State.WANDER
# Next tile first
var _path: Array[Vector2i] = []
var _goal: Vector2i
var _target_room: int = NO_ROOM
var _last_seen: Vector2i
var _search_turns_left: int = 0

@onready var _entity: Entity = get_parent() as Entity


func _ready() -> void:
    _entity.set_turn(_take_turn)
    _entity.placed.connect(_reset)


func _take_turn() -> void:
    var state: FloorState = _entity.floor_state
    var here: Vector2i = _entity.grid_position

    if state.player != null and Sight.can_see(state, here, state.player.grid_position):
        _state = MobAI.State.PURSUE
        _last_seen = state.player.grid_position
        if _can_attack(state):
            await _attack(state)
            return
        _path = _path_to(state, _last_seen)
    elif _state == MobAI.State.PURSUE:
        _state = MobAI.State.SEARCH
        _path = _path_to(state, _last_seen)
        _search_turns_left = _path.size() + SEARCH_SLACK

    if _state == MobAI.State.SEARCH:
        _search_turns_left -= 1
        if here == _last_seen or _search_turns_left < 0:
            _reset()
        elif _path.is_empty():
            _path = _path_to(state, _last_seen)

    if _state == MobAI.State.WANDER and (_path.is_empty() or _in_target_room(state)):
        _plan_wander(state)
    _follow_path(state)


# Same rules as the player's cast
func _can_attack(state: FloorState) -> bool:
    var direction: Vector2i = state.player.grid_position - _entity.grid_position
    return (
        RunRules.is_adjacent(state.player.grid_position, _entity.grid_position)
        and not MoveRules.cuts_corner(state.grid, _entity.grid_position, direction)
    )


# The turn waits for the attack to play out, so attacks happen one at a time
func _attack(state: FloorState) -> void:
    await state.wait_for_slides()
    _entity.face(state.player.grid_position - _entity.grid_position)
    _entity.hold(BasicSpell.DURATION)
    BasicSpell.cast(_entity)
    await _entity.finish_slide()


# Blocked by an entity, it tries a short detour, otherwise waits and replans next turn
func _follow_path(state: FloorState) -> void:
    if _path.is_empty():
        return
    var direction: Vector2i = _path[0] - _entity.grid_position
    if not MoveRules.can_step(state, _entity.grid_position, direction):
        var detour: Array[Vector2i] = _path_around_entities(state)
        if detour.is_empty() or detour.size() > _path.size() + DETOUR_LIMIT:
            _path.clear()
            return
        _path = detour
        direction = _path[0] - _entity.grid_position
        if not MoveRules.can_step(state, _entity.grid_position, direction):
            _path.clear()
            return
    _path.remove_at(0)
    _entity.step(direction, state.step_duration)


# Paths to a random tile in a random other room
func _plan_wander(state: FloorState) -> void:
    _path.clear()
    var current_room: int = state.grid.get_tile(_entity.grid_position).room_id

    var choices: Array[DungeonRoom] = []
    for room: DungeonRoom in state.rooms:
        if room.id != current_room:
            choices.append(room)
    if choices.is_empty():
        return
    var target: DungeonRoom = choices[state.rng.randi_range(0, choices.size() - 1)]

    var tiles: Array[Vector2i] = []
    for p: Vector2i in state.reachable_tiles:
        if state.grid.get_tile(p).room_id == target.id:
            tiles.append(p)
    if tiles.is_empty():
        return

    _target_room = target.id
    _path = _path_to(state, tiles[state.rng.randi_range(0, tiles.size() - 1)])


func _path_to(state: FloorState, goal: Vector2i) -> Array[Vector2i]:
    _goal = goal
    var path: Array[Vector2i] = state.pathfinder.get_id_path(_entity.grid_position, goal)
    if not path.is_empty():
        path.remove_at(0) # Its own tile
    return path


# Other entities count as walls, except one standing on the goal
func _path_around_entities(state: FloorState) -> Array[Vector2i]:
    var blocked: Array[Vector2i] = []
    for entity: Entity in state.occupancy.get_entities():
        var p: Vector2i = entity.grid_position
        if entity == _entity or p == _goal or state.pathfinder.is_point_solid(p):
            continue
        state.pathfinder.set_point_solid(p, true)
        blocked.append(p)
    var path: Array[Vector2i] = _path_to(state, _goal)
    for p: Vector2i in blocked:
        state.pathfinder.set_point_solid(p, false)
    return path


func _in_target_room(state: FloorState) -> bool:
    return state.grid.get_tile(_entity.grid_position).room_id == _target_room


func _reset() -> void:
    _state = MobAI.State.WANDER
    _path.clear()
    _target_room = NO_ROOM
