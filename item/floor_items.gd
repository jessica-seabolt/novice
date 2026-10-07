class_name FloorItems extends Node2D
## The items lying on the current floor

const ITEM_SCENE: PackedScene = preload("res://item/item.tscn")

var _tilemap_layer: TileMapLayer
var _items: Dictionary[Vector2i, Item] = {}


func setup(tilemap_layer: TileMapLayer) -> void:
    _tilemap_layer = tilemap_layer


func clear() -> void:
    for child: Node in get_children():
        child.queue_free()
    _items.clear()


func has_item(p: Vector2i) -> bool:
    return _items.has(p)


## Null if nothing's there
func get_stack(p: Vector2i) -> ItemStack:
    return _items[p].stack if _items.has(p) else null


func place(stack: ItemStack, p: Vector2i) -> void:
    var item: Item = ITEM_SCENE.instantiate()
    add_child(item)
    item.setup(stack, _tilemap_layer, p)
    _items[p] = item


## Off the floor at once; the sprite lingers for delay seconds
func take(p: Vector2i, delay: float = 0.0) -> ItemStack:
    var item: Item = _items[p]
    _items.erase(p)
    item.remove_after(delay)
    return item.stack
