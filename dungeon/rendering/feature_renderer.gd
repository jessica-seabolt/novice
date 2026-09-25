class_name FeatureRenderer extends RefCounted
## Draws features like stairs onto the feature layer

const GENERIC_SOURCE_ID: int = 0
const STAIRS_UP_TILE: Vector2i = Vector2i(0, 0)
const STAIRS_DOWN_TILE: Vector2i = Vector2i(1, 0)


static func render(
    grid: FloorGrid, layer: TileMapLayer, stair_direction: DungeonConfig.StairDirection
) -> void:
    layer.clear()
    var stairs_tile: Vector2i = (
        STAIRS_UP_TILE
        if stair_direction == DungeonConfig.StairDirection.UP
        else STAIRS_DOWN_TILE
    )

    for y: int in range(grid.height):
        for x: int in range(grid.width):
            var p: Vector2i = Vector2i(x, y)
            match grid.get_tile(p).feature:
                DungeonTile.Feature.STAIRS:
                    layer.set_cell(p, GENERIC_SOURCE_ID, stairs_tile)
