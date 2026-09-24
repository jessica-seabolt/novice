class_name HallwayCarver extends RefCounted
## Carves hallways into the floor, using A* to route them between rooms

## The maximum number of attempts to find a valid path
const MAX_ATTEMPTS: int = 100

## A snake hallway gets one waypoint per this many tiles between its doors
const SNAKE_TILES_PER_WAYPOINT: int = 18
## The most waypoints a snake hallway can have
const SNAKE_WAYPOINTS_MAX: int = 3
## How far a waypoint can stray from the straight line between the doors
const SNAKE_WANDER: int = 6

## Shortest and longest a dead end can be
const DEAD_END_LENGTH_MIN: int = 3
const DEAD_END_LENGTH_MAX: int = 15
## Chance a dead end turns at each step
const DEAD_END_TURN_CHANCE: float = 0.25


## Builds this floor's A* grid, with rooms and the border marked solid
static func build_astar(ctx: GenerationContext) -> void:
    var astar: AStarGrid2D = AStarGrid2D.new()
    astar.region = Rect2i(0, 0, ctx.grid.width, ctx.grid.height)
    astar.cell_size = Vector2(1, 1)
    astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
    astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
    astar.update()

    for y: int in range(ctx.grid.height):
        for x: int in range(ctx.grid.width):
            var p: Vector2i = Vector2i(x, y)
            if ctx.grid.is_room(p) or ctx.grid.is_border(p):
                astar.set_point_solid(p, true)

    ctx.astar = astar


## Carves a hallway between the closest doors of two rooms
static func carve_between(ctx: GenerationContext, room_a: DungeonRoom, room_b: DungeonRoom) -> void:
    var doors: Array[Vector2i] = _best_door_pair(ctx.grid, room_a, room_b)
    if doors.is_empty():
        return

    var path: Array[Vector2i] = _find_path(ctx, doors[0], doors[1])
    _carve(ctx.grid, path)


## Carves a hallway between two rooms that winds through random waypoints
static func carve_snake_between(
    ctx: GenerationContext, room_a: DungeonRoom, room_b: DungeonRoom
) -> void:
    var doors: Array[Vector2i] = _best_door_pair(ctx.grid, room_a, room_b)
    if doors.is_empty():
        return

    var start: Vector2i = doors[0]
    var goal: Vector2i = doors[1]

    # Longer hallways get more waypoints, so they wind about as often per tile
    var distance: int = absi(start.x - goal.x) + absi(start.y - goal.y)
    var count: int = clampi(
        floori(float(distance) / SNAKE_TILES_PER_WAYPOINT), 1, SNAKE_WAYPOINTS_MAX
    )

    var points: Array[Vector2i] = [start]
    for k: int in range(1, count + 1):
        var t: float = float(k) / float(count + 1)
        points.append(_snake_waypoint(ctx, start, goal, t))
    points.append(goal)

    # A leg that can't be pathed skips its waypoint
    # The next leg starts from the last point reached
    var carved: Dictionary = {}
    var current: Vector2i = start
    for i: int in range(1, points.size()):
        var path: Array[Vector2i] = _find_path(ctx, current, points[i])
        if path.is_empty():
            continue
        for p: Vector2i in path:
            if ctx.grid.is_wall(p):
                carved[p] = true
        _carve(ctx.grid, path)
        current = points[i]

    _trim_dead_ends(ctx.grid, carved)


## Carves a hallway loop just inside the border and returns its tiles
## Rooms touching the loop become part of it rather than being detoured around
static func carve_ring(ctx: GenerationContext) -> Array[Vector2i]:
    var interior: Rect2i = ctx.grid.get_interior()
    var first: Vector2i = interior.position
    var last: Vector2i = interior.end - Vector2i.ONE

    # Clockwise from the top-left
    var corners: Array[Vector2i] = [
        first,
        Vector2i(last.x, first.y),
        last,
        Vector2i(first.x, last.y),
    ]

    var carved: Dictionary = {}
    for i: int in range(corners.size()):
        var next: Vector2i = corners[(i + 1) % corners.size()]
        var step: Vector2i = (next - corners[i]).sign()
        var p: Vector2i = corners[i]
        while p != next:
            _carve_ring_tile(ctx.grid, p, step, carved)
            p += step

    # Skipping tiles beside a room can strand one-tile nubs at its corners
    _trim_dead_ends(ctx.grid, carved)

    var ring: Array[Vector2i] = []
    ring.assign(carved.keys())
    return ring


## Carves a hallway from a room's closest door to the closest tile of the ring
static func carve_to_ring(
    ctx: GenerationContext, room: DungeonRoom, ring: Array[Vector2i]
) -> void:
    var pair: Array[Vector2i] = _closest_pair(_door_candidates(ctx.grid, room), ring)
    if pair.is_empty():
        return

    var path: Array[Vector2i] = _find_path(ctx, pair[0], pair[1])
    _carve(ctx.grid, path)


## Carves a short hallway out of a hallway tile that leads nowhere
## Returns false and carves nothing if it couldn't reach the minimum length
static func carve_dead_end(ctx: GenerationContext, from: Vector2i) -> bool:
    var length: int = ctx.rng.randi_range(DEAD_END_LENGTH_MIN, DEAD_END_LENGTH_MAX)
    var cardinals: Array[Vector2i] = FloorGrid.CARDINALS
    var direction: Vector2i = cardinals[ctx.rng.randi_range(0, cardinals.size() - 1)]
    var tiles: Array[Vector2i] = []
    var p: Vector2i = from

    for _step: int in range(length):
        # Turning swaps x and y for a perpendicular direction, then picks which side
        if not tiles.is_empty() and ctx.rng.randf() < DEAD_END_TURN_CHANCE:
            var side: int = 1 if ctx.rng.randf() < 0.5 else -1
            direction = Vector2i(direction.y, direction.x) * side

        var next: Vector2i = p + direction
        if not _can_extend_dead_end(ctx.grid, next, p):
            break
        ctx.grid.set_tile_type(next, DungeonTile.TileType.GROUND)
        tiles.append(next)
        p = next

    if tiles.size() >= DEAD_END_LENGTH_MIN:
        return true

    for t: Vector2i in tiles:
        ctx.grid.set_tile_type(t, DungeonTile.TileType.WALL)
    return false


# Asks A* for a route, then walks it as if carving it
# Tiles cutting through a room or making a 2x2 ground square get blocked
# Repeats until a clean route is found or MAX_ATTEMPTS is exhausted
static func _find_path(ctx: GenerationContext, start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
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


static func _carve(grid: FloorGrid, path: Array[Vector2i]) -> void:
    for p: Vector2i in path:
        if not grid.is_room(p):
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)


static func _best_door_pair(
    grid: FloorGrid, room_a: DungeonRoom, room_b: DungeonRoom
) -> Array[Vector2i]:
    var doors_a: Array[Vector2i] = _door_candidates(grid, room_a)
    var doors_b: Array[Vector2i] = _door_candidates(grid, room_b)
    return _closest_pair(doors_a, doors_b)


static func _door_candidates(grid: FloorGrid, room: DungeonRoom) -> Array[Vector2i]:
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


# The closest pair of points between two lists, or an empty array if either list is empty
static func _closest_pair(a: Array[Vector2i], b: Array[Vector2i]) -> Array[Vector2i]:
    if a.is_empty() or b.is_empty():
        return []

    var best_a: Vector2i = a[0]
    var best_b: Vector2i = b[0]
    var best_distance: int = -1

    for point_a: Vector2i in a:
        for point_b: Vector2i in b:
            var distance: int = absi(point_a.x - point_b.x) + absi(point_a.y - point_b.y)
            if best_distance == -1 or distance < best_distance:
                best_distance = distance
                best_a = point_a
                best_b = point_b

    return [best_a, best_b]


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


# A point partway along the line from start to goal, nudged randomly and kept off the border
static func _snake_waypoint(
    ctx: GenerationContext, start: Vector2i, goal: Vector2i, t: float
) -> Vector2i:
    var on_line: Vector2i = Vector2i(Vector2(start).lerp(Vector2(goal), t).round())
    var nudge: Vector2i = Vector2i(
        ctx.rng.randi_range(-SNAKE_WANDER, SNAKE_WANDER),
        ctx.rng.randi_range(-SNAKE_WANDER, SNAKE_WANDER)
    )

    var interior: Rect2i = ctx.grid.get_interior()
    return (on_line + nudge).clamp(interior.position, interior.end - Vector2i.ONE)


# Skips the middle of any stretch running alongside a room, which would otherwise be 2x2 ground
# Both ends of the stretch still get carved, so they meet the room and it carries the ring across
static func _carve_ring_tile(
    grid: FloorGrid, p: Vector2i, step: Vector2i, carved: Dictionary
) -> void:
    # Going clockwise, the inside of the ring is always a right turn from the step
    var inward: Vector2i = Vector2i(-step.y, step.x)
    var mid_stretch: bool = (
        grid.is_room(p + inward)
        and grid.is_room(p - step + inward)
        and grid.is_room(p + step + inward)
    )

    # The 2x2 check still catches a room tucked into a corner of the ring
    if mid_stretch or not grid.is_wall(p) or _would_create_2x2(grid, p, {}):
        return
    grid.set_tile_type(p, DungeonTile.TileType.GROUND)
    carved[p] = true


# Walls back up any carved tile with at most one ground neighbour, until none are left
static func _trim_dead_ends(grid: FloorGrid, carved: Dictionary) -> void:
    var trimmed: bool = true
    while trimmed:
        trimmed = false
        for p: Vector2i in carved.keys():
            if _ground_neighbour_count(grid, p) > 1:
                continue
            grid.set_tile_type(p, DungeonTile.TileType.WALL)
            carved.erase(p)
            trimmed = true


static func _ground_neighbour_count(grid: FloorGrid, p: Vector2i) -> int:
    var count: int = 0
    for direction: Vector2i in FloorGrid.CARDINALS:
        if grid.is_ground(p + direction):
            count += 1
    return count


# A dead end can only grow into rock that touches no ground but the tile it came from
static func _can_extend_dead_end(grid: FloorGrid, next: Vector2i, from: Vector2i) -> bool:
    if grid.is_border(next) or not grid.is_wall(next):
        return false
    for direction: Vector2i in FloorGrid.CARDINALS:
        var neighbour: Vector2i = next + direction
        if neighbour != from and grid.is_ground(neighbour):
            return false
    return true
