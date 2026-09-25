class_name MoveRules extends RefCounted
## Decides whether an entity can take a step


static func can_step(state: FloorState, from: Vector2i, direction: Vector2i) -> bool:
    var grid: FloorGrid = state.grid
    var to: Vector2i = from + direction
    if not grid.is_ground(to) or state.occupancy.is_occupied(to):
        return false

    return not cuts_corner(grid, from, direction)


## Whether a diagonal from "from" crosses the corner of a wall
static func cuts_corner(grid: FloorGrid, from: Vector2i, direction: Vector2i) -> bool:
    if direction.x == 0 or direction.y == 0:
        return false
    return (
        grid.is_wall(from + Vector2i(direction.x, 0))
        or grid.is_wall(from + Vector2i(0, direction.y))
    )
