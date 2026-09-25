class_name WanderAI extends Node
## Walks its entity from room to room

const NO_ROOM: int = -1

# Next tile first
var _path: Array[Vector2i] = []
var _target_room: int = NO_ROOM

@onready var _entity: Entity = get_parent() as Entity


func _ready() -> void:
    _entity.set_turn(_take_turn)
    _entity.placed.connect(_forget_target)


# A blocked step waits and replans next turn
func _take_turn() -> void:
    var state: FloorState = _entity.floor_state
    if _path.is_empty() or _in_target_room(state):
        _plan(state)
    if _path.is_empty():
        return # Only one room

    var direction: Vector2i = _path[0] - _entity.grid_position
    if not MoveRules.can_step(state, _entity.grid_position, direction):
        _path.clear()
        return

    _path.remove_at(0)
    _entity.step(direction, state.step_duration)


# Paths to a random tile in a random other room
func _plan(state: FloorState) -> void:
    _path.clear()
    var here: Vector2i = _entity.grid_position
    var current_room: int = state.grid.get_tile(here).room_id

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
    var goal: Vector2i = tiles[state.rng.randi_range(0, tiles.size() - 1)]
    _path = state.pathfinder.get_id_path(here, goal)
    if not _path.is_empty():
        _path.remove_at(0) # Its own tile


func _in_target_room(state: FloorState) -> bool:
    return state.grid.get_tile(_entity.grid_position).room_id == _target_room


func _forget_target() -> void:
    _path.clear()
    _target_room = NO_ROOM
