class_name FloorValidator extends RefCounted
## Makes sure every room can be reached from every other room on foot, carving links if not


## Connects any rooms that can't be reached without crossing walls or special terrain
static func validate(ctx: GenerationContext) -> void:
    # Each repair links at least one more room, so this many is always enough
    for _repair: int in range(ctx.rooms.size()):
        var labels: Dictionary = _label_regions(ctx.grid)
        var region_rooms: Dictionary = _rooms_by_region(ctx.grid, labels)
        var main: int = _region_with_most_rooms(region_rooms)
        if main == -1 or region_rooms[main].size() == ctx.rooms.size():
            return

        var path: Array[Vector2i] = _path_to_missing_room(ctx.grid, labels, region_rooms, main)
        if path.is_empty():
            push_error("FloorValidator couldn't connect every room")
            return
        for p: Vector2i in path:
            ctx.grid.set_tile_type(p, DungeonTile.TileType.GROUND)


# Maps every ground tile to the number of the connected region it belongs to
static func _label_regions(grid: FloorGrid) -> Dictionary:
    var labels: Dictionary = {}
    var next_region: int = 0

    for y: int in range(grid.height):
        for x: int in range(grid.width):
            var p: Vector2i = Vector2i(x, y)
            if not grid.is_ground(p) or labels.has(p):
                continue
            _flood_fill(grid, p, next_region, labels)
            next_region += 1

    return labels


static func _flood_fill(grid: FloorGrid, start: Vector2i, region: int, labels: Dictionary) -> void:
    var queue: Array[Vector2i] = [start]
    labels[start] = region
    var head: int = 0

    while head < queue.size():
        var p: Vector2i = queue[head]
        head += 1

        for direction: Vector2i in FloorGrid.CARDINALS:
            var neighbour: Vector2i = p + direction
            if not grid.is_ground(neighbour) or labels.has(neighbour):
                continue
            labels[neighbour] = region
            queue.append(neighbour)


# For each region that holds room tiles, the set of room ids it touches
static func _rooms_by_region(grid: FloorGrid, labels: Dictionary) -> Dictionary:
    var region_rooms: Dictionary = {}

    for p: Vector2i in labels:
        var room_id: int = grid.get_tile(p).room_id
        if room_id == -1:
            continue
        var region: int = labels[p]
        if not region_rooms.has(region):
            region_rooms[region] = {}
        region_rooms[region][room_id] = true

    return region_rooms


static func _region_with_most_rooms(region_rooms: Dictionary) -> int:
    var best: int = -1
    for region: int in region_rooms:
        if best == -1 or region_rooms[region].size() > region_rooms[best].size():
            best = region
    return best


# Shortest route from the main region, through walls and special terrain, to a region holding
# a room the main region can't reach yet
static func _path_to_missing_room(
    grid: FloorGrid, labels: Dictionary, region_rooms: Dictionary, main: int
) -> Array[Vector2i]:
    var came_from: Dictionary = {}
    var queue: Array[Vector2i] = []
    for p: Vector2i in labels:
        if labels[p] == main:
            came_from[p] = p # Starting tiles point to themselves
            queue.append(p)

    var head: int = 0
    while head < queue.size():
        var p: Vector2i = queue[head]
        head += 1

        for direction: Vector2i in FloorGrid.CARDINALS:
            var next: Vector2i = p + direction
            if grid.is_border(next) or came_from.has(next):
                continue
            came_from[next] = p
            if labels.has(next) and _has_missing_room(region_rooms, labels[next], main):
                return _trace_back(came_from, p)
            queue.append(next)

    var no_path: Array[Vector2i] = []
    return no_path


static func _has_missing_room(region_rooms: Dictionary, region: int, main: int) -> bool:
    if not region_rooms.has(region):
        return false
    for room_id: int in region_rooms[region]:
        if not region_rooms[main].has(room_id):
            return true
    return false


# Follows came_from links back to the main region, collecting every tile along the way
static func _trace_back(came_from: Dictionary, from: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var p: Vector2i = from
    while came_from[p] != p:
        path.append(p)
        p = came_from[p]
    return path
