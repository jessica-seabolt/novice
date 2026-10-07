class_name HeldItem extends Node
## The item an entity has equipped

signal changed

## Picks up what it steps on while empty-handed, for entities with no inventory
@export var picks_up: bool = false

var stack: ItemStack

@onready var _entity: Entity = get_parent() as Entity


## Null if the entity can't hold items
static func of(entity: Entity) -> HeldItem:
    return entity.get_node_or_null("HeldItem") as HeldItem


func _ready() -> void:
    if picks_up:
        _entity.stepped.connect(_on_stepped)


func equip(item_stack: ItemStack) -> void:
    stack = item_stack
    changed.emit()


func unequip() -> void:
    stack = null
    changed.emit()


## On its tile or one beside it; lost if there's no room
func drop() -> void:
    if stack == null:
        return
    var state: FloorState = _entity.floor_state
    var tiles: Array[Vector2i] = [_entity.grid_position]
    for side: Vector2i in FloorGrid.CARDINALS:
        tiles.append(_entity.grid_position + side)
    for p: Vector2i in tiles:
        if state.can_hold_item(p):
            state.items.place(stack, p)
            SignalBus.item_dropped.emit(_entity, stack)
            break
    unequip()


func _on_stepped() -> void:
    var state: FloorState = _entity.floor_state
    if stack != null or not state.items.has_item(_entity.grid_position):
        return
    equip(state.items.take(_entity.grid_position, state.step_duration))
    SignalBus.item_picked_up.emit(_entity, stack)
