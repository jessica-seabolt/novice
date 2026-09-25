class_name FloorGrid extends RefCounted
## A floor's tiles, with methods for reading and changing them

const BORDER_SIZE: int = 2
const MAX_WIDTH: int = 84
const MAX_HEIGHT: int = 52

## The four straight directions
const CARDINALS: Array[Vector2i] = [
    Vector2i(0, -1), # Up
    Vector2i(1, 0), # Right
    Vector2i(0, 1), # Down
    Vector2i(-1, 0), # Left
]

var width: int = 0
var height: int = 0

var _tiles: Array[Array] = []


func reset() -> void:
    for y: int in range(height):
        for x: int in range(width):
            _tiles[y][x].reset()
    _enforce_border()


func get_tile(p: Vector2i) -> DungeonTile:
    return _tiles[p.y][p.x]


func is_in_bounds(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func is_ground(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].tile_type == DungeonTile.TileType.GROUND


func is_wall(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].tile_type == DungeonTile.TileType.WALL


func is_special_terrain(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].tile_type == DungeonTile.TileType.SPECIAL_TERRAIN


func is_room(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].room_id != -1


## Ground that isn't part of a room
func is_hallway(p: Vector2i) -> bool:
    return is_ground(p) and not is_room(p)


## A room tile with a hallway right beside it
func is_doorway(p: Vector2i) -> bool:
    if not is_room(p):
        return false
    for side: Vector2i in CARDINALS:
        if is_hallway(p + side):
            return true
    return false


func count_ground_tiles() -> int:
    var count: int = 0
    for y: int in range(height):
        for x: int in range(width):
            if _tiles[y][x].tile_type == DungeonTile.TileType.GROUND:
                count += 1
    return count


func set_tile_type(p: Vector2i, type: DungeonTile.TileType) -> void:
    # Never allows setting border tiles
    if is_border(p):
        return
    _tiles[p.y][p.x].tile_type = type


func build(new_width: int, new_height: int) -> void:
    width = new_width
    height = new_height
    _tiles.clear()

    for _y: int in range(height):
        var row: Array = []
        for _x: int in range(width):
            row.append(DungeonTile.new())
        _tiles.append(row)

    _enforce_border()


func is_border(p: Vector2i) -> bool:
    return (
        p.x < BORDER_SIZE
        or p.y < BORDER_SIZE
        or p.x >= (width - BORDER_SIZE)
        or p.y >= (height - BORDER_SIZE)
    )


## Everything inside the border
func get_interior() -> Rect2i:
    return Rect2i(BORDER_SIZE, BORDER_SIZE, width - BORDER_SIZE * 2, height - BORDER_SIZE * 2)


func print_grid() -> void:
    for y: int in range(height):
        var row: String = ""
        for x: int in range(width):
            var tile: DungeonTile = _tiles[y][x]
            if tile.tile_type == DungeonTile.TileType.WALL:
                row += "X"
            elif tile.tile_type == DungeonTile.TileType.SPECIAL_TERRAIN:
                row += "~"
            elif tile.feature == DungeonTile.Feature.STAIRS:
                row += "S"
            elif tile.room_id == -1:
                row += "."
            else:
                # Last digit only, to keep columns aligned
                row += "%s" % (tile.room_id % 10)
        print(row)


func _enforce_border() -> void:
    for y: int in range(height):
        for x: int in range(width):
            var p: Vector2i = Vector2i(x, y)
            if not is_border(p):
                continue

            var tile: DungeonTile = _tiles[y][x]
            tile.tile_type = DungeonTile.TileType.WALL
            tile.room_id = -1
            tile.feature = DungeonTile.Feature.NONE
