class_name HallwayGenerator extends RefCounted
## Connects rooms in a dungeon by carving hallways between them


## Links every room into one chain of hallways, visiting rooms in nearest-neighbour order
static func generate(ctx: GenerationContext) -> void:
    HallwayCarver.build_astar(ctx)

    var order: Array[int] = _nearest_neighbour_order(ctx.rooms)
    for i: int in range(order.size() - 1):
        var room_a: DungeonRoom = ctx.rooms[order[i]]
        var room_b: DungeonRoom = ctx.rooms[order[i + 1]]
        HallwayCarver.carve_between(ctx, room_a, room_b)


## Greedy walk from the leftmost room, linking each room to the nearest unvisited room
static func _nearest_neighbour_order(rooms: Array[DungeonRoom]) -> Array[int]:
    var visited: Array[bool] = []
    visited.resize(rooms.size())
    visited.fill(false)

    var order: Array[int] = []
    var current: int = _leftmost_room_index(rooms)
    visited[current] = true
    order.append(current)

    for _step: int in range(rooms.size() - 1):
        var nearest: int = _nearest_unvisited(rooms, visited, current)
        visited[nearest] = true
        order.append(nearest)
        current = nearest

    return order


static func _leftmost_room_index(rooms: Array[DungeonRoom]) -> int:
    var best: int = 0
    var best_center: Vector2i = rooms[0].get_center()

    for i: int in range(1, rooms.size()):
        var center: Vector2i = rooms[i].get_center()
        if center.x < best_center.x or (center.x == best_center.x and center.y < best_center.y):
            best = i
            best_center = center

    return best


static func _nearest_unvisited(rooms: Array[DungeonRoom], visited: Array[bool], from: int) -> int:
    var best: int = -1
    var best_distance: int = -1

    for i: int in range(rooms.size()):
        if visited[i]:
            continue
        var distance: int = _distance(rooms, from, i)
        if best_distance == -1 or distance < best_distance:
            best_distance = distance
            best = i

    return best


static func _distance(rooms: Array[DungeonRoom], a_idx: int, b_idx: int) -> int:
    var a: Vector2i = rooms[a_idx].get_center()
    var b: Vector2i = rooms[b_idx].get_center()
    return absi(a.x - b.x) + absi(a.y - b.y)
