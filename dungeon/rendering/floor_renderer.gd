class_name FloorRenderer extends RefCounted
# Renders DungeonTiles to the TileMapLayer

const PADDING: int = 10


enum TerrainSet { # TODO: Add more?
    DEFAULT
}


enum Terrain {
    WALL,
    GROUND,
    SPECIAL_TERRAIN
}


static func render(grid: FloorGrid, layer: TileMapLayer) -> void:
    layer.clear()

    var wall_tiles: Array[Vector2i] = []
    var ground_tiles: Array[Vector2i] = []
    var special_terrain_tiles: Array[Vector2i] = []

    for y in range(grid.HEIGHT):
        for x in range(grid.WIDTH):
            var tile: DungeonTile = grid.get_tile(Vector2i(x, y))

            match tile.tile_type:
                DungeonTile.TileType.WALL:
                    wall_tiles.append(Vector2i(x, y))
                DungeonTile.TileType.GROUND:
                    ground_tiles.append(Vector2i(x, y))
                DungeonTile.TileType.SPECIAL_TERRAIN:
                    special_terrain_tiles.append(Vector2i(x, y))

    wall_tiles.append_array(_padding_cells(grid))

    layer.set_cells_terrain_connect(ground_tiles, TerrainSet.DEFAULT, Terrain.GROUND)
    layer.set_cells_terrain_connect(wall_tiles, TerrainSet.DEFAULT, Terrain.WALL)
    layer.set_cells_terrain_connect(
        special_terrain_tiles, TerrainSet.DEFAULT, Terrain.SPECIAL_TERRAIN
    )

# Used to pad out the border visually so the player doesn't see void
static func _padding_cells(grid: FloorGrid) -> Array[Vector2i]:
    var padding_cells: Array[Vector2i] = []

    for y in range(-PADDING, FloorGrid.HEIGHT + PADDING):
        for x in range(-PADDING, FloorGrid.WIDTH + PADDING):
            var p: Vector2i = Vector2i(x, y)
            if not grid.is_in_bounds(p):
                padding_cells.append(p)

    return padding_cells
