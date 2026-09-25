class_name Sight extends RefCounted
## Whether one tile can see another: anywhere in the same room, otherwise within a few steps

## Walking steps away something can be seen from outside a shared room
const RANGE: int = 5


static func can_see(state: FloorState, a: Vector2i, b: Vector2i) -> bool:
    var room: int = state.grid.get_tile(a).room_id
    if room != -1 and room == state.grid.get_tile(b).room_id:
        return true
    if absi(a.x - b.x) > RANGE or absi(a.y - b.y) > RANGE:
        return false
    var path: Array[Vector2i] = state.pathfinder.get_id_path(a, b)
    return not path.is_empty() and path.size() - 1 <= RANGE
