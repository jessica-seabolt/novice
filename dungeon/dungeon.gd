class_name Dungeon extends Node2D

const TEST_CONFIG = preload("res://dungeon/config/dc_test.tres")
@onready var tilemap_layer: TileMapLayer = $TileMapLayer
var config: DungeonConfig
var grid: FloorGrid

func _ready() -> void:
    config = TEST_CONFIG
    generate_floor()


func generate_floor() -> void:
    grid = FloorGrid.new()
    grid.build()

    var ctx: GenerationContext = GenerationContext.new(grid, config)
    RoomPlacer.place(ctx)
    RoomConnector.connect_rooms(ctx)
    FloorRenderer.render(grid, tilemap_layer)
    grid.print_grid()
