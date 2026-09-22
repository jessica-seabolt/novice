class_name RoomPlacer extends RefCounted
## Handles room placement for a dungeon floor

const MAX_PLACEMENT_ATTEMPTS: int = 10


## The context's "rooms" array will be populated with the placed rooms
static func place(ctx: GenerationContext) -> void:
    # Resolve RANDOM once so every call below agrees on the same concrete orientation
    var orientation: SectorLayout.Orientation = SectorLayout.resolve_orientation(
        ctx.config.orientation, ctx.rng
    )

    # Determine how many rooms to place and how to divide the dungeon into sectors
    var target_count: int = ctx.rng.randi_range(
        ctx.config.room_count_min, ctx.config.room_count_max
    )
    var sectors: Vector2i = SectorLayout.sector_grid_size(target_count, orientation)
    var valid_sectors: Array[Vector2i] = SectorLayout.valid_sectors(target_count, orientation)

    # One room per valid sector
    for sector: Vector2i in valid_sectors:
        for _attempt: int in range(MAX_PLACEMENT_ATTEMPTS):
            var rect: Rect2i = RoomShapes.generate(sectors.x, sectors.y, sector, ctx)
            if not _respects_gap(ctx.rooms, rect):
                continue
            _stamp(ctx.grid, ctx.make_room(rect))
            break

    # If any sector never got a room, use the fallback room
    if ctx.rooms.size() < valid_sectors.size():
        _place_fallback_room(ctx)
    else:
        _combine_rooms(ctx)


# Guarantees a valid floor by generating a single room that fills all usable area
static func _place_fallback_room(ctx: GenerationContext) -> void:
    ctx.grid.reset()
    ctx.reset_rooms()

    var border: int = FloorGrid.BORDER_SIZE
    var rect: Rect2i = Rect2i(
        border, border, ctx.grid.width - border * 2, ctx.grid.height - border * 2
    )

    _stamp(ctx.grid, ctx.make_room(rect))


# Rolls each room's chance to swallow its closest neighbour into one bigger room
static func _combine_rooms(ctx: GenerationContext) -> void:
    for room: DungeonRoom in ctx.rooms.duplicate():
        if not ctx.rooms.has(room) or room.has_merged:
            continue
        if ctx.rng.randf() >= ctx.config.room_combination_chance:
            continue

        var neighbour: DungeonRoom = _closest_room(ctx.rooms, room)
        if neighbour != null:
            _try_combine(ctx, room, neighbour)


# The nearest other unmerged room to "from", or null if there isn't one
static func _closest_room(rooms: Array[DungeonRoom], from: DungeonRoom) -> DungeonRoom:
    var closest: DungeonRoom = null
    var closest_distance: int = -1

    for room: DungeonRoom in rooms:
        if room == from or room.has_merged:
            continue
        var distance: int = _room_distance(from, room)
        if closest_distance == -1 or distance < closest_distance:
            closest_distance = distance
            closest = room

    return closest


static func _room_distance(a: DungeonRoom, b: DungeonRoom) -> int:
    var a_center: Vector2i = a.get_center()
    var b_center: Vector2i = b.get_center()
    return absi(a_center.x - b_center.x) + absi(a_center.y - b_center.y)


# Swallows "neighbour" into "first" unless it would touch a third room
static func _try_combine(
    ctx: GenerationContext, first: DungeonRoom, neighbour: DungeonRoom
) -> void:
    var merged_area: Rect2i = first.area.merge(neighbour.area)

    for room: DungeonRoom in ctx.rooms:
        if room == first or room == neighbour:
            continue
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(merged_area):
            return

    first.area = merged_area
    first.has_merged = true
    ctx.rooms.erase(neighbour)
    _stamp(ctx.grid, first)


static func _respects_gap(rooms: Array[DungeonRoom], rect: Rect2i) -> bool:
    for room: DungeonRoom in rooms:
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(rect):
            return false
    return true


static func _stamp(grid: FloorGrid, room: DungeonRoom) -> void:
    for y: int in range(room.area.position.y, room.area.end.y):
        for x: int in range(room.area.position.x, room.area.end.x):
            var p: Vector2i = Vector2i(x, y)
            grid.get_tile(p).room_id = room.id
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)

