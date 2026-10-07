class_name Item extends AnimatedSprite2D
## A pile of items lying on a floor tile

var stack: ItemStack


func setup(item_stack: ItemStack, tilemap_layer: TileMapLayer, tile: Vector2i) -> void:
    stack = item_stack
    sprite_frames = stack.item.sprite_frames
    SpriteAnchor.apply(self, stack.item.sprite_anchor)
    play()
    position = tilemap_layer.map_to_local(tile)


## Stays visible a moment to account for the time it takes for whoever took it to arrive
func remove_after(delay: float) -> void:
    var tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.tween_interval(delay)
    tween.tween_callback(queue_free)
