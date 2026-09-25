class_name Dungeon extends Node2D
## Generates dungeon floors for a player to explore

const TEST_CONFIG = preload("res://dungeon/config/dc_test.tres")
const PLAYER_SCENE: PackedScene = preload("res://entity/player/player.tscn")
const MOB_SCENE: PackedScene = preload("res://entity/mob/mob.tscn")

var config: DungeonConfig
var floor_state: FloorState
var player: Entity
var turn_system: TurnSystem
var floor_number: int = 1
var mobs: Array[Entity] = []

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var feature_layer: TileMapLayer = $FeatureLayer


func _ready() -> void:
    config = TEST_CONFIG
    _spawn_player()
    _setup_turn_system()
    _start_floor()


# Builds a fresh floor, puts the player on it, and starts taking turns
func _start_floor() -> void:
    var ctx: GenerationContext = _generate_floor()
    floor_state = FloorState.new(ctx.grid, ctx.rooms, ctx.reachable_tiles, ctx.rng)
    player.setup(floor_state, floor_layer, ctx.player_spawn)
    _spawn_mobs(ctx)
    print("Floor ", floor_number)
    turn_system.run()


func _on_actor_acted(actor: Entity) -> void:
    if actor != player:
        return
    if floor_state.grid.get_tile(player.grid_position).feature != DungeonTile.Feature.STAIRS:
        return
    if floor_number >= config.floor_count:
        return # The last floor's stairs lead nowhere yet
    turn_system.stop()
    floor_number += 1
    _start_floor.call_deferred()


func _generate_floor() -> GenerationContext:
    var grid: FloorGrid = FloorGrid.new()
    var floor_width: int = floori(float(FloorGrid.MAX_WIDTH) * config.grid_usage)
    var floor_height: int = floori(float(FloorGrid.MAX_HEIGHT) * config.grid_usage)
    grid.build(floor_width, floor_height)

    var ctx: GenerationContext = GenerationContext.new(grid, config)
    RoomGenerator.generate(ctx)
    HallwayGenerator.generate(ctx)
    SpecialTerrainGenerator.generate(ctx)
    FloorValidator.validate(ctx)
    SpawnGenerator.generate(ctx)
    FloorRenderer.render(grid, floor_layer)
    FeatureRenderer.render(grid, feature_layer, config.stair_direction)
    if DebugConfig.DEBUG_GRID:
        grid.print_grid()

    return ctx


func _spawn_player() -> void:
    player = PLAYER_SCENE.instantiate()
    add_child(player)


func _spawn_mobs(ctx: GenerationContext) -> void:
    _reset_mobs()

    for spawn: Vector2i in ctx.mob_spawns:
        var mob: Entity = MOB_SCENE.instantiate()
        add_child(mob)
        mob.setup(floor_state, floor_layer, spawn)
        turn_system.add_actor(mob)
        mobs.append(mob)


func _reset_mobs() -> void:
    for mob: Entity in mobs:
        turn_system.remove_actor(mob)
        mob.queue_free()

    mobs.clear()


func _setup_turn_system() -> void:
    turn_system = TurnSystem.new()
    turn_system.add_actor(player)
    turn_system.actor_acted.connect(_on_actor_acted)
