class_name ItemData extends Resource
## What an item is called, looks like, and does when used

@export var display_name: String
@export_multiline var description: String
@export var sprite_frames: SpriteFrames
## How many can share one inventory slot
@export_range(1, 99) var max_stack: int = 1
## Applied in order
@export var effects: Array[Effect] = []


func is_usable() -> bool:
    return not effects.is_empty()


func use(user: Entity) -> void:
    for effect: Effect in effects:
        effect.apply(user, user)
