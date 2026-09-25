class_name RunRules extends RefCounted
## Decides when a run stops


## Whether a run standing on "at" should take another step in "direction"
static func should_continue(state: FloorState, at: Vector2i, direction: Vector2i) -> bool:
    var grid: FloorGrid = state.grid
    if not MoveRules.can_step(state, at, direction):
        return false
    # Always stops beside stairs, so they can't be run past by accident
    if _near_stairs(grid, at):
        return false
    if _next_to_entity(state, at):
        return false

    if grid.is_room(at):
        # Stops on a doorway, whether arriving through it or passing one
        if grid.is_doorway(at):
            return false
    elif grid.is_room(at + direction):
        # Stops on a hallway's last tile rather than stepping into a room
        return false

    # Diagonal runs never check for side passages
    return _is_diagonal(direction) or not _side_passage(grid, at, direction)


# A walkable tile directly to the left or right, with a wall at either end of it along the run,
# means a passage opens off there
static func _side_passage(grid: FloorGrid, at: Vector2i, direction: Vector2i) -> bool:
    var across: Vector2i = Vector2i(direction.y, direction.x)
    for side: Vector2i in [across, -across]:
        var beside: Vector2i = at + side
        if not grid.is_ground(beside):
            continue
        if not grid.is_ground(beside - direction) or not grid.is_ground(beside + direction):
            return true
    return false


# Temporary: the original games stop a run when a mob comes into view, which needs line of sight
static func _next_to_entity(state: FloorState, at: Vector2i) -> bool:
    for y: int in range(-1, 2):
        for x: int in range(-1, 2):
            if (x != 0 or y != 0) and state.occupancy.is_occupied(at + Vector2i(x, y)):
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
