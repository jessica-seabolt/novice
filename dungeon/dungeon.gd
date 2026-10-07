class_name Dungeon extends Node2D
## Builds each floor and runs its turns

const TEST_CONFIG: DungeonConfig = preload("res://dungeon/config/dungeon_config_test.tres")
const PLAYER_SCENE: PackedScene = preload("res://entity/player/player.tscn")
const MOB_SCENE: PackedScene = preload("res://entity/mob/mob.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var config: DungeonConfig
var floor_state: FloorState
var player: Entity
var turn_system: TurnSystem
var floor_number: int = 1
var mobs: Array[Entity] = []
var hud: Hud
# Right after the floor layers, so items draw under entities
var _floor_items: FloorItems = FloorItems.new()
# To tell arriving on stairs from standing on them
var _player_last_position: Vector2i

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var feature_layer: TileMapLayer = $FeatureLayer


func _ready() -> void:
    config = TEST_CONFIG
    _floor_items.name = "Items"
    _floor_items.setup(floor_layer)
    feature_layer.add_sibling(_floor_items)
    hud = HUD_SCENE.instantiate()
    add_child(hud)
    add_child(DamageNumbers.new())
    add_child(CombatSounds.new())
    add_child(SpellFlash.new())
    _spawn_player()
    hud.setup(player)
    _setup_turn_system()
    SignalBus.entity_defeated.connect(_on_entity_defeated)
    _start_floor()


func _start_floor() -> void:
    var ctx: GenerationContext = _generate_floor()
    floor_state = FloorState.new(ctx.grid, ctx.rooms, ctx.reachable_tiles, ctx.rng)
    floor_state.player = player
    floor_state.items = _floor_items
    player.setup(floor_state, floor_layer, ctx.player_spawn)
    _player_last_position = ctx.player_spawn
    _spawn_mobs(ctx)
    _spawn_items(ctx)
    turn_system.run()


# Asked once the round comes back to the player, so mobs get to act first
func _before_turn(actor: Entity) -> void:
    if actor != player:
        return
    var arrived: bool = player.grid_position != _player_last_position
    _player_last_position = player.grid_position
    if not arrived:
        return
    if floor_state.grid.get_tile(player.grid_position).feature != DungeonTile.Feature.STAIRS:
        return
    if floor_number >= config.floor_count:
        return # The last floor's stairs lead nowhere yet
    await floor_state.wait_for_slides()
    if await hud.ask("Proceed to the next floor?", ["Yes", "No"]) != 0:
        return
    turn_system.stop()
    floor_number += 1
    _start_floor.call_deferred()


func _on_entity_defeated(entity: Entity) -> void:
    if entity == player:
        # For now, losing restarts the dungeon
        turn_system.stop()
        await _vanish(player)
        await hud.show_log()
        floor_number = 1
        Stats.of(player).restore()
        Inventory.of(player).clear()
        hud.clear_log()
        _start_floor.call_deferred()
        return

    var reward: int = Stats.of(entity).stat_block.stat_point_reward
    Stats.of(player).stat_points += reward
    if reward > 0:
        var noun: String = "stat point" if reward == 1 else "stat points"
        hud.add_message("%s gained %d %s" % [player.display_name, reward, noun])
    HeldItem.of(entity).drop()
    _take_off_floor(entity)
    await _vanish(entity)
    entity.queue_free()


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
    if config.mob_pool.is_empty():
        return

    for spawn: Vector2i in ctx.mob_spawns:
        var mob: Entity = _make_mob(_pick_mob())
        add_child(mob)
        mob.setup(floor_state, floor_layer, spawn)
        turn_system.add_actor(mob)
        mobs.append(mob)


# Stats and Spellbook read the stat block when added, so it's set before then
func _make_mob(data: MobData) -> Entity:
    var mob: Entity = MOB_SCENE.instantiate()
    mob.display_name = data.display_name
    var sprite: AnimatedSprite2D = mob.get_node("AnimatedSprite2D")
    sprite.sprite_frames = data.sprite_frames
    sprite.play()
    Stats.of(mob).stat_block = data.stat_block
    return mob


func _pick_mob() -> MobData:
    var weights: Array[int] = []
    for entry: MobSpawn in config.mob_pool:
        weights.append(entry.weight)
    return config.mob_pool[Dice.pick_weighted(weights, floor_state.rng)].mob


func _spawn_items(ctx: GenerationContext) -> void:
    _floor_items.clear()
    if config.item_pool.is_empty():
        return

    for spawn: Vector2i in ctx.item_spawns:
        _floor_items.place(_pick_item_stack(), spawn)


func _pick_item_stack() -> ItemStack:
    var weights: Array[int] = []
    for entry: ItemSpawn in config.item_pool:
        weights.append(entry.weight)
    var entry: ItemSpawn = config.item_pool[Dice.pick_weighted(weights, floor_state.rng)]
    var count: int = floor_state.rng.randi_range(entry.count_min, entry.count_max)
    return ItemStack.new(entry.item, mini(count, entry.item.max_stack))


func _reset_mobs() -> void:
    for mob: Entity in mobs.duplicate():
        _remove_mob(mob)


func _remove_mob(mob: Entity) -> void:
    _take_off_floor(mob)
    mob.queue_free()


# Out of play, though still visible while it vanishes
func _take_off_floor(mob: Entity) -> void:
    turn_system.remove_actor(mob)
    mob.floor_state.occupancy.remove(mob.grid_position)
    mobs.erase(mob)


func _vanish(entity: Entity) -> void:
    var flicker: DamageFlicker = DamageFlicker.of(entity)
    if flicker != null:
        await flicker.vanish()


func _setup_turn_system() -> void:
    turn_system = TurnSystem.new()
    turn_system.add_actor(player)
    turn_system.before_turn = _before_turn
