class_name RoomShapes extends RefCounted
## Proposes a room's size and position within a given sector

const ROOM_GAP: int = 1


static func generate(
    sectors_across: int, sectors_down: int, sector: Vector2i, ctx: GenerationContext
) -> Rect2i:

    # Find box's position and size on the grid
    var usable_width: int = ctx.grid.width - FloorGrid.BORDER_SIZE * 2
    var usable_height: int = ctx.grid.height - FloorGrid.BORDER_SIZE * 2
    var sector_width: int = floori(float(usable_width) / float(sectors_across))
    var sector_height: int = floori(float(usable_height) / float(sectors_down))

    var sector_left: int = FloorGrid.BORDER_SIZE + sector.x * sector_width
    var sector_top: int = FloorGrid.BORDER_SIZE + sector.y * sector_height

    # Room size won't exceed sector size minus gap
    var sector_max_width: int = sector_width - ROOM_GAP * 2
    var sector_max_height: int = sector_height - ROOM_GAP * 2
    var max_room_width: int = mini(ctx.config.room_width_max, sector_max_width)
    var max_room_height: int = mini(ctx.config.room_height_max, sector_max_height)

    # Generate a random room size within the constraints
    var room_width: int = ctx.rng.randi_range(
        ctx.config.room_width_min, maxi(ctx.config.room_width_min, max_room_width)
    )
    var room_height: int = ctx.rng.randi_range(
        ctx.config.room_height_min, maxi(ctx.config.room_height_min, max_room_height)
    )

    # Roll random position for the room
    var min_x: int = sector_left + ROOM_GAP
    var min_y: int = sector_top + ROOM_GAP
    var max_x: int = sector_left + sector_width - room_width - ROOM_GAP
    var max_y: int = sector_top + sector_height - room_height - ROOM_GAP

    var x: int = ctx.rng.randi_range(min_x, maxi(min_x, max_x))
    var y: int = ctx.rng.randi_range(min_y, maxi(min_y, max_y))

    return Rect2i(x, y, room_width, room_height)
