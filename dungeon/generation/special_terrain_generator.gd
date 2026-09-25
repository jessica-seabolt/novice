class_name SpecialTerrainGenerator extends RefCounted
## Decides how many lakes and rivers to make, and where they start

## Tries to find a lake start
const LAKE_START_ATTEMPTS: int = 200
## Tries to find a river start
const RIVER_START_ATTEMPTS: int = 250
## Returned when no start was found
const NO_START: Vector2i = Vector2i(-1, -1)


static func generate(ctx: GenerationContext) -> void:
    var lake_count: int = ctx.rng.randi_range(
        ctx.config.lake_count_min, ctx.config.lake_count_max
    )
    var river_count: int = ctx.rng.randi_range(
        ctx.config.river_count_min, ctx.config.river_count_max
    )

    for _lake: int in range(lake_count):
        var start: Vector2i = _find_lake_start(ctx)
        # Later attempts would fail too
        if start == NO_START:
            break
        SpecialTerrainCarver.carve_lake(ctx.grid, start, ctx.rng)

    for _river: int in range(river_count):
        var from_top: bool = ctx.rng.randf() < 0.5
        var start: Vector2i = _find_river_start(ctx, from_top)
        if start == NO_START:
            continue

        var heading: Vector2i = Vector2i(0, 1) if from_top else Vector2i(0, -1)
        SpecialTerrainCarver.carve_river(ctx.grid, start, heading, ctx.rng)


# A random interior wall tile, or NO_START
static func _find_lake_start(ctx: GenerationContext) -> Vector2i:
    var border: int = FloorGrid.BORDER_SIZE
    for _attempt: int in range(LAKE_START_ATTEMPTS):
        var p: Vector2i = Vector2i(
            ctx.rng.randi_range(border, ctx.grid.width - 1 - border),
            ctx.rng.randi_range(border, ctx.grid.height - 1 - border)
        )
        if ctx.grid.is_wall(p):
            return p
    return NO_START


# A wall tile on the top or bottom interior row, or NO_START
static func _find_river_start(ctx: GenerationContext, from_top: bool) -> Vector2i:
    var border: int = FloorGrid.BORDER_SIZE
    var row: int = border if from_top else ctx.grid.height - 1 - border

    for _attempt: int in range(RIVER_START_ATTEMPTS):
        var p: Vector2i = Vector2i(
            ctx.rng.randi_range(border, ctx.grid.width - 1 - border),
            row
        )
        if ctx.grid.is_wall(p):
            return p
    return NO_START
