class_name MoveRules extends RefCounted
## Decides whether an entity can take a step


static func can_step(state: FloorState, from: Vector2i, direction: Vector2i) -> bool:
    var grid: FloorGrid = state.grid
    var to: Vector2i = from + direction
    if not grid.is_ground(to) or state.occupancy.is_occupied(to):
        return false

    # A diagonal step can't cut across the corner of a wall
    if direction.x != 0 and direction.y != 0:
        var beside_x: Vector2i = from + Vector2i(direction.x, 0)
        var beside_y: Vector2i = from + Vector2i(0, direction.y)
        if grid.is_wall(beside_x) or grid.is_wall(beside_y):
            return false

    return true
