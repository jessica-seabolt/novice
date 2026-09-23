class_name Dungeon extends Node2D
## Generates dungeon floors for a player to explore

const TEST_CONFIG = preload("res://dungeon/config/dc_test.tres")
var config: DungeonConfig
var grid: FloorGrid
@onready var tilemap_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
    config = TEST_CONFIG
    generate_floor()


func generate_floor() -> void:
    grid = FloorGrid.new()
    var floor_width: int = floori(float(FloorGrid.MAX_WIDTH) * config.grid_usage)
    var floor_height: int = floori(float(FloorGrid.MAX_HEIGHT) * config.grid_usage)
    grid.build(floor_width, floor_height)

    var ctx: GenerationContext = GenerationContext.new(grid, config)
    RoomGenerator.generate(ctx)
    HallwayGenerator.generate(ctx)
    SpecialTerrainGenerator.generate(ctx)
    FloorRenderer.render(grid, tilemap_layer)
    grid.print_grid()
