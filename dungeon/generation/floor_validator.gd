class_name FloorValidator extends RefCounted
## Makes sure every room can reach every other room on foot


## Carves links until one ground region touches every room
static func validate(ctx: GenerationContext) -> void:
    # Each repair reaches at least one more room
    for _repair: int in range(ctx.rooms.size()):
        var labels: Dictionary = _label_regions(ctx.grid)
        var region_rooms: Dictionary = _rooms_by_region(ctx.grid, labels)
        var main: int = _main_region(region_rooms, _region_sizes(labels))
        if main == -1 or region_rooms[main].size() == ctx.rooms.size():
            ctx.reachable_tiles = _tiles_in_region(labels, main)
            return

        var path: Array[Vector2i] = _path_to_missing_room(ctx.grid, labels, region_rooms, main)
        if path.is_empty():
            push_error("FloorValidator couldn't connect every room")
            return
        for p: Vector2i in path:
            ctx.grid.set_tile_type(p, DungeonTile.TileType.GROUND)


# Maps each ground tile to its region number
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


# Region number to the set of room ids it touches
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


# Most rooms wins; ties go to the bigger region
static func _main_region(region_rooms: Dictionary, region_sizes: Dictionary) -> int:
    var best: int = -1
    for region: int in region_rooms:
        if best == -1:
            best = region
            continue
        var rooms_here: int = region_rooms[region].size()
        var rooms_best: int = region_rooms[best].size()
        var bigger: bool = region_sizes[region] > region_sizes[best]
        if rooms_here > rooms_best or (rooms_here == rooms_best and bigger):
            best = region
    return best


# Shortest route through walls and water to a region with a missing room
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


# Walks came_from back to the main region
static func _trace_back(came_from: Dictionary, from: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = []
    var p: Vector2i = from
    while came_from[p] != p:
        path.append(p)
        p = came_from[p]
    return path


static func _tiles_in_region(labels: Dictionary, region: int) -> Array[Vector2i]:
    var tiles: Array[Vector2i] = []
    for p: Vector2i in labels:
        if labels[p] == region:
            tiles.append(p)
    return tiles


static func _region_sizes(labels: Dictionary) -> Dictionary:
    var sizes: Dictionary = {}
    for p: Vector2i in labels:
        sizes[labels[p]] = sizes.get(labels[p], 0) + 1
    return sizes
