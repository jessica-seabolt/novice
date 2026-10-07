class_name Inventory extends Node
## The items an entity carries

signal changed
signal requested(stack: ItemStack, action: Inventory.Action)

enum Action {
    USE,
    DROP,
}

## Seconds using or dropping an item takes
const ACTION_DURATION: float = 0.3

## Slots for items in the inventory
@export_range(1, 50) var item_slots: int = 5

var stacks: Array[ItemStack] = []

@onready var _entity: Entity = get_parent() as Entity
@onready var _held: HeldItem = HeldItem.of(_entity)


## Null if the entity carries nothing
static func of(entity: Entity) -> Inventory:
    return entity.get_node_or_null("Inventory") as Inventory


func _ready() -> void:
    _entity.stepped.connect(_on_stepped)


## Fills existing stacks first, then empty slots; returns how many didn't fit
func add(stack: ItemStack) -> int:
    var left: int = stack.count
    for slot: ItemStack in stacks:
        if slot.item == stack.item and left > 0:
            var moved: int = mini(left, slot.item.max_stack - slot.count)
            slot.count += moved
            left -= moved
    while left > 0 and stacks.size() < item_slots:
        var moved: int = mini(left, stack.item.max_stack)
        stacks.append(ItemStack.new(stack.item, moved))
        left -= moved
    if left < stack.count:
        changed.emit()
    return left


## For whoever controls the entity; using and dropping take a turn
func request(stack: ItemStack, action: Inventory.Action) -> void:
    requested.emit(stack, action)


func can_drop() -> bool:
    return _entity.floor_state.can_hold_item(_entity.grid_position)


func use(stack: ItemStack) -> void:
    SignalBus.item_used.emit(_entity, stack.item)
    stack.item.use(_entity)
    stack.count -= 1
    if stack.count <= 0:
        remove(stack)
    else:
        changed.emit()


func drop(stack: ItemStack) -> void:
    remove(stack)
    _entity.floor_state.items.place(stack, _entity.grid_position)
    SignalBus.item_dropped.emit(_entity, stack)


func is_equipped(stack: ItemStack) -> bool:
    return _held != null and _held.stack == stack


func equip(stack: ItemStack) -> void:
    _held.equip(stack)
    SignalBus.item_equipped.emit(_entity, stack)
    changed.emit()


func unequip() -> void:
    _held.unequip()
    changed.emit()


func remove(stack: ItemStack) -> void:
    stacks.erase(stack)
    if is_equipped(stack):
        _held.unequip()
    changed.emit()


func clear() -> void:
    stacks.clear()
    if _held != null:
        _held.unequip()
    changed.emit()


# Whatever doesn't fit stays on the floor
func _on_stepped() -> void:
    var state: FloorState = _entity.floor_state
    var here: Vector2i = _entity.grid_position
    var stack: ItemStack = state.items.get_stack(here)
    if stack == null:
        return
    var left: int = add(stack)
    if left == stack.count:
        SignalBus.no_room_for.emit(_entity, stack)
        return
    SignalBus.item_picked_up.emit(_entity, ItemStack.new(stack.item, stack.count - left))
    if left == 0:
        state.items.take(here, state.step_duration)
    else:
        stack.count = left
