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


static func visible_tiles(state: FloorState, from: Vector2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    var room_id: int = state.grid.get_tile(from).room_id
    for room: DungeonRoom in state.rooms:
        if room.id != room_id:
            continue
        for y: int in range(room.area.position.y, room.area.end.y):
            for x: int in range(room.area.position.x, room.area.end.x):
                var p: Vector2i = Vector2i(x, y)
                if state.grid.get_tile(p).room_id == room_id and not state.grid.is_wall(p):
                    result.append(p)

    # Beyond the room, only nearby tiles can be seen
    for y: int in range(from.y - RANGE, from.y + RANGE + 1):
        for x: int in range(from.x - RANGE, from.x + RANGE + 1):
            var p: Vector2i = Vector2i(x, y)
            if not state.grid.is_in_bounds(p):
                continue
            var in_room: bool = room_id != -1 and state.grid.get_tile(p).room_id == room_id
            if not in_room and can_see(state, from, p):
                result.append(p)
    return result
