class_name ItemStack extends RefCounted
## Some number of one item, carried or lying on the floor

var item: ItemData
var count: int


func _init(stack_item: ItemData, stack_count: int = 1) -> void:
    item = stack_item
    count = stack_count


## Returns an item's display name, with its count if there's more than one
func get_label() -> String:
    return item.display_name if count == 1 else "%s x%d" % [item.display_name, count]
