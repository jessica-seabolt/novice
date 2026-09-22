class_name FloorGrid extends RefCounted

const BORDER_SIZE: int = 2
const WIDTH: int = 54
const HEIGHT: int = 32

# Uses a 2D Array to store the grid
var _tiles: Array[Array] = []


func reset() -> void:
    for y: int in range(HEIGHT):
        for x: int in range(WIDTH):
            _tiles[y][x].reset()
    _enforce_border()


func get_tile(p: Vector2i) -> DungeonTile:
    return _tiles[p.y][p.x]


func is_in_bounds(p: Vector2i) -> bool:
    return p.x >= 0 and p.y >= 0 and p.x < WIDTH and p.y < HEIGHT
    

func is_ground(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].tile_type == DungeonTile.TileType.GROUND


func is_wall(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].tile_type == DungeonTile.TileType.WALL


func is_room(p: Vector2i) -> bool:
    return _tiles[p.y][p.x].room_id != -1


# A ground tile that is not part of any room, i.e. a corridor
func is_hallway(p: Vector2i) -> bool:
    return is_ground(p) and not is_room(p)
    
    
func count_ground_tiles() -> int:
    var count: int = 0
    for y: int in range(HEIGHT):
        for x: int in range(WIDTH):
            if _tiles[y][x].tile_type == DungeonTile.TileType.GROUND:
                count += 1
    return count


func set_tile_type(p: Vector2i, type: DungeonTile.TileType) -> void:
    # Never allows setting border tiles
    if is_border(p):
        return
    _tiles[p.y][p.x].tile_type = type


func build() -> void:
    _tiles.clear()

    for y: int in range(HEIGHT):
        var row: Array = []
        for x: int in range(WIDTH):
            row.append(DungeonTile.new())
        _tiles.append(row)

    _enforce_border()


func is_border(p: Vector2i) -> bool:
    return (
        p.x < BORDER_SIZE
        or p.y < BORDER_SIZE
        or p.x >= (WIDTH - BORDER_SIZE)
        or p.y >= (HEIGHT - BORDER_SIZE)
    )


func print_grid() -> void:
    for y: int in range(HEIGHT):
        var row: String = ""
        for x: int in range(WIDTH):
            var tile: DungeonTile = _tiles[y][x]
            if tile.tile_type == DungeonTile.TileType.WALL:
                row += "X"
            elif tile.room_id == -1:
                row += "."
            else:
                row += "%s" % tile.room_id
        print(row)


# Ensures the border is always TileType.WALL
func _enforce_border() -> void:
    for y: int in range(HEIGHT):
        for x: int in range(WIDTH):
            var p: Vector2i = Vector2i(x, y)
            if not is_border(p):
                continue

            var tile: DungeonTile = _tiles[y][x]
            tile.tile_type = DungeonTile.TileType.WALL
            tile.room_id = -1
            tile.is_stairs = false
