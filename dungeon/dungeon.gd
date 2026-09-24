class_name Dungeon extends Node2D
## Generates dungeon floors for a player to explore

const TEST_CONFIG = preload("res://dungeon/config/dc_test.tres")
const PLAYER_SCENE: PackedScene = preload("res://entity/player/player.tscn")

var config: DungeonConfig
var grid: FloorGrid
var player: Player
var turn_system: TurnSystem

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
    FloorValidator.validate(ctx)
    SpawnGenerator.generate(ctx)
    FloorRenderer.render(grid, tilemap_layer)
    _spawn_player(ctx)
    _setup_turn_system()
    grid.print_grid()


func _spawn_player(ctx: GenerationContext) -> void:
    player = PLAYER_SCENE.instantiate()
    add_child(player)
    player.setup(grid, tilemap_layer, ctx.player_spawn)


func _setup_turn_system() -> void:
    turn_system = TurnSystem.new()
    turn_system.add_actor(player)
    turn_system.run()
