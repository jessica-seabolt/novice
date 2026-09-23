class_name FloorRenderer extends RefCounted
## Renders DungeonTiles to the TileMapLayer

# Values must match the terrain indices in the TileSet's Better Terrain setup
enum Terrain {
    WALL,
    GROUND,
    SPECIAL_TERRAIN,
}

const PADDING: int = 10
const TERRAIN_FOR_TILE: Dictionary = {
    DungeonTile.TileType.WALL: FloorRenderer.Terrain.WALL,
    DungeonTile.TileType.GROUND: FloorRenderer.Terrain.GROUND,
    DungeonTile.TileType.SPECIAL_TERRAIN: FloorRenderer.Terrain.SPECIAL_TERRAIN,
}


## Paints the grid onto the layer, surrounded by PADDING tiles of wall so the player
## doesn't see void past the edge
static func render(grid: FloorGrid, layer: TileMapLayer) -> void:
    layer.clear()

    var origin: Vector2i = Vector2i(-PADDING, -PADDING)
    var size: Vector2i = Vector2i(grid.width + PADDING * 2, grid.height + PADDING * 2)
    var terrains: PackedInt32Array = PackedInt32Array()
    terrains.resize(size.x * size.y)
    for y: int in range(size.y):
        for x: int in range(size.x):
            terrains[y * size.x + x] = _terrain_at(grid, origin + Vector2i(x, y))

    # Counting beyond the padding as wall keeps the padding's outer edge solid too
    Autotiler.paint(layer, terrains, origin, size, FloorRenderer.Terrain.WALL)


# Padding outside the grid is wall
static func _terrain_at(grid: FloorGrid, p: Vector2i) -> int:
    return (
        TERRAIN_FOR_TILE[grid.get_tile(p).tile_type]
        if grid.is_in_bounds(p)
        else FloorRenderer.Terrain.WALL
    )
