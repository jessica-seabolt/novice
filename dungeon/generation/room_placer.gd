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
            stamp(ctx.grid, ctx.make_room(rect))
            break

    # If any sector never got a room, use the fallback room
    if ctx.rooms.size() < valid_sectors.size():
        _place_fallback_room(ctx)
    else:
        RoomCombiner.combine_rooms(ctx)


## Writes a room's area into the grid as ground, tagged with its id
static func stamp(grid: FloorGrid, room: DungeonRoom) -> void:
    for y: int in range(room.area.position.y, room.area.end.y):
        for x: int in range(room.area.position.x, room.area.end.x):
            var p: Vector2i = Vector2i(x, y)
            grid.get_tile(p).room_id = room.id
            grid.set_tile_type(p, DungeonTile.TileType.GROUND)


# Guarantees a valid floor by generating a single room that fills all usable area
static func _place_fallback_room(ctx: GenerationContext) -> void:
    ctx.grid.reset()
    ctx.reset_rooms()

    var border: int = FloorGrid.BORDER_SIZE
    var rect: Rect2i = Rect2i(
        border, border, ctx.grid.width - border * 2, ctx.grid.height - border * 2
    )

    stamp(ctx.grid, ctx.make_room(rect))


static func _respects_gap(rooms: Array[DungeonRoom], rect: Rect2i) -> bool:
    for room: DungeonRoom in rooms:
        if room.area.grow(RoomShapes.ROOM_GAP).intersects(rect):
            return false
    return true
