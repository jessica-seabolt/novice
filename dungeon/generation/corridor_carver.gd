class_name CorridorCarver extends RefCounted
## Carves straight L-shaped corridors between two points

const MAX_ATTEMPTS: int = 100


static func find_path(ctx: GenerationContext, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
    var temp_blocked: Array[Vector2i] = []

    for _attempt: int in range(MAX_ATTEMPTS):
        var raw_path: PackedVector2Array = ctx.astar.get_point_path(start, goal)
        if raw_path.is_empty():
            _unblock(ctx.astar, temp_blocked)
            return []

        var path: Array[Vector2i] = []
        for point: Vector2 in raw_path:
            path.append(Vector2i(point))

        var planned: Dictionary = {}
        var bad_tile: Vector2i
        var found_bad_tile: bool = false

        for p: Vector2i in path:
            if ctx.grid.is_room(p):
                bad_tile = p
                found_bad_tile = true
                break
            if ctx.grid.is_ground(p):
                planned[p] = true
                continue
            if _would_create_2x2(ctx.grid, p, planned):
                bad_tile = p
                found_bad_tile = true
                break
            planned[p] = true

        if not found_bad_tile:
            _unblock(ctx.astar, temp_blocked)
            return path

        ctx.astar.set_point_solid(bad_tile, true)
        temp_blocked.append(bad_tile)

    _unblock(ctx.astar, temp_blocked)
    return []


static func _unblock(astar: AStarGrid2D, blocked: Array[Vector2i]) -> void:
    for p: Vector2i in blocked:
        astar.set_point_solid(p, false)


static func build_astar(ctx: GenerationContext) -> void:
    var astar: AStarGrid2D = AStarGrid2D.new()
    astar.region = Rect2i(0, 0, FloorGrid.WIDTH, FloorGrid.HEIGHT)
    astar.cell_size = Vector2(1, 1)
    astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar.update()

    for y: int in range(FloorGrid.HEIGHT):
        for x: int in range(FloorGrid.WIDTH):
            var p: Vector2i = Vector2i(x, y)
            if ctx.grid.is_room(p):
                astar.set_point_solid(p, true)

    ctx.astar = astar


static func get_door_candidates(grid: FloorGrid, room: DungeonRoom) -> Array[Vector2i]:
    var a: Rect2i = room.area
    var candidates: Array[Vector2i] = []

    # Left and right cells for each row, top and bottom cells for each column
    for y: int in range(a.position.y, a.end.y):
        candidates.append(Vector2i(a.position.x - 1, y))
        candidates.append(Vector2i(a.end.x, y))
    for x: int in range(a.position.x, a.end.x):
        candidates.append(Vector2i(x, a.position.y - 1))
        candidates.append(Vector2i(x, a.end.y))

    var valid: Array[Vector2i] = []
    for p: Vector2i in candidates:
        if grid.is_in_bounds(p) and not grid.is_room(p):
            valid.append(p)
    return valid


static func best_door_pair(
    grid: FloorGrid, room_a: DungeonRoom, room_b: DungeonRoom
) -> Array[Vector2i]:
    var doors_a: Array[Vector2i] = get_door_candidates(grid, room_a)
    var doors_b: Array[Vector2i] = get_door_candidates(grid, room_b)
    if doors_a.is_empty() or doors_b.is_empty():
        return []

    var best_a: Vector2i = doors_a[0]
    var best_b: Vector2i = doors_b[0]
    var best_distance: int = -1

    # Find the closest pair of doors between the two rooms
    for door_a: Vector2i in doors_a:
        for door_b: Vector2i in doors_b:
            var distance: int = absi(door_a.x - door_b.x) + absi(door_a.y - door_b.y)
            if best_distance == -1 or distance < best_distance:
                best_distance = distance
                best_a = door_a
                best_b = door_b

    return [best_a, best_b]


static func carve(grid: FloorGrid, path: Array[Vector2i]) -> void:
    for p: Vector2i in path:
        if not grid.is_room(p):
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)



static func _would_create_2x2(grid: FloorGrid, p: Vector2i, planned: Dictionary) -> bool:
    var origins: Array[Vector2i] = [
        Vector2i(p.x - 1, p.y - 1),
        Vector2i(p.x, p.y - 1),
        Vector2i(p.x - 1, p.y),
        Vector2i(p.x, p.y),
    ]

    # Check each of the four possible 2x2 squares that could be formed with the new tile
    for origin: Vector2i in origins:
        var corners: Array[Vector2i] = [
            origin,
            Vector2i(origin.x + 1, origin.y),
            Vector2i(origin.x, origin.y + 1),
            Vector2i(origin.x + 1, origin.y + 1),
        ]
        if _all_would_be_ground(grid, corners, p, planned):
            return true
    return false


static func _all_would_be_ground(
    grid: FloorGrid, corners: Array[Vector2i], p: Vector2i, planned: Dictionary
) -> bool:
    # Compare each corner of a 2x2 square to see if it would be ground after carving
    for c: Vector2i in corners:
        if not grid.is_in_bounds(c):
            return false
        if c != p and not grid.is_ground(c) and not planned.has(c):
            return false
    return true


static func carve_between(ctx: GenerationContext, room_a: DungeonRoom, room_b: DungeonRoom) -> void:
    var doors: Array[Vector2i] = best_door_pair(ctx.grid, room_a, room_b)
    if doors.is_empty():
        return

    var path: Array[Vector2i] = find_path(ctx, doors[0], doors[1])
    carve(ctx.grid, path)
