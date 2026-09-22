class_name RoomShapes extends RefCounted
## Assigns room shapes to sectors of the dungeon grid


const MIN_ROOM_W: int = 4
const MIN_ROOM_H: int = 5
const ROOM_GAP: int = 1


static func sector_grid_size(target_rooms: int) -> Vector2i:
    var sectors_across: int = ceil(sqrt(target_rooms))
    var sectors_down: int = ceil(float(target_rooms) / float(sectors_across))
    return Vector2i(sectors_across, sectors_down)


static func generate(
    sectors_across: int, sectors_down: int, sector: Vector2i, ctx: GenerationContext
) -> Rect2i:

    # Find box's position and size on the grid
    var usable_width: int = FloorGrid.WIDTH - FloorGrid.BORDER_SIZE * 2
    var usable_height: int = FloorGrid.HEIGHT - FloorGrid.BORDER_SIZE * 2
    var sector_width: int = floori(float(usable_width) / float(sectors_across))
    var sector_height: int = floori(float(usable_height) / float(sectors_down))

    var sector_left: int = FloorGrid.BORDER_SIZE + sector.x * sector_width
    var sector_top: int = FloorGrid.BORDER_SIZE + sector.y * sector_height

    # Calculate room size constraints
    var max_room_width: int = sector_width - ROOM_GAP * 2
    var max_room_height: int = sector_height - ROOM_GAP * 2

    # Generate a random room size within the constraints
    var room_width: int = ctx.rng.randi_range(MIN_ROOM_W, maxi(MIN_ROOM_W, max_room_width))
    var room_height: int = ctx.rng.randi_range(MIN_ROOM_H, maxi(MIN_ROOM_H, max_room_height))

    # Roll random position for the room
    var min_x: int = sector_left + ROOM_GAP
    var min_y: int = sector_top + ROOM_GAP
    var max_x: int = sector_left + sector_width - room_width - ROOM_GAP
    var max_y: int = sector_top + sector_height - room_height - ROOM_GAP

    var x: int = ctx.rng.randi_range(min_x, maxi(min_x, max_x))
    var y: int = ctx.rng.randi_range(min_y, maxi(min_y, max_y))

    return Rect2i(x, y, room_width, room_height)
