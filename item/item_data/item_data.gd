class_name ItemData extends Resource
## What an item is called, looks like, and does when used

@export var display_name: String
@export_multiline var description: String
## What the item menu calls using it, like Learn for a scroll
@export var use_label: String = "Use"
@export var sprite_frames: SpriteFrames
## The pixel placed on the tile's centre; SpriteAnchor.MIDDLE for the middle
@export var sprite_anchor: Vector2i = SpriteAnchor.MIDDLE
## How many can share one inventory slot
@export_range(1, 99) var max_stack: int = 1
## Applied in order
@export var effects: Array[Effect] = []


## The first frame of its sprite, for menus
func get_icon() -> Texture2D:
    return sprite_frames.get_frame_texture(sprite_frames.get_animation_names()[0], 0)


func can_use(user: Entity) -> bool:
    if effects.is_empty():
        return false
    for effect: Effect in effects:
        if not effect.can_apply(user):
            return false
    return true


func heals() -> bool:
    for effect: Effect in effects:
        if effect is HealEffect:
            return true
    return false


func use(user: Entity) -> void:
    for effect: Effect in effects:
        effect.apply(user, user)
