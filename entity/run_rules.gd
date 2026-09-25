class_name RunRules extends RefCounted
## Decides when a run stops


static func should_continue(state: FloorState, at: Vector2i, direction: Vector2i) -> bool:
    var grid: FloorGrid = state.grid
    if not MoveRules.can_step(state, at, direction):
        return false
    # Always, so stairs can't be run past
    if _near_stairs(grid, at):
        return false

    if grid.is_room(at):
        # Arriving through a doorway or passing one
        if grid.is_doorway(at):
            return false
    elif grid.is_room(at + direction):
        # Stop before entering a room
        return false

    # Diagonal runs never check for side passages
    return _is_diagonal(direction) or not _side_passage(grid, at, direction)


# Open ground beside the runner with a wall at either end along the run
static func _side_passage(grid: FloorGrid, at: Vector2i, direction: Vector2i) -> bool:
    var across: Vector2i = Vector2i(direction.y, direction.x)
    for side: Vector2i in [across, -across]:
        var beside: Vector2i = at + side
        if not grid.is_ground(beside):
            continue
        if not grid.is_ground(beside - direction) or not grid.is_ground(beside + direction):
            return true
    return false


## Whether stepping from "from" puts the runner next to an entity it wasn't already next to
## Temporary until line of sight
static func steps_into_contact(state: FloorState, from: Vector2i, direction: Vector2i) -> bool:
    var to: Vector2i = from + direction
    for y: int in range(-1, 2):
        for x: int in range(-1, 2):
            var p: Vector2i = to + Vector2i(x, y)
            if p == to or p == from or not state.occupancy.is_occupied(p):
                continue
            if absi(p.x - from.x) > 1 or absi(p.y - from.y) > 1:
                return true
    return false


static func _near_stairs(grid: FloorGrid, at: Vector2i) -> bool:
    for y: int in range(-1, 2):
        for x: int in range(-1, 2):
            if grid.get_tile(at + Vector2i(x, y)).feature == DungeonTile.Feature.STAIRS:
                return true
    return false


static func _is_diagonal(direction: Vector2i) -> bool:
    return direction.x != 0 and direction.y != 0
