class_name MobData extends Resource
## Defines a mob's display name, sprite frames, stats, and starting spells

@export var display_name: String
@export var sprite_frames: SpriteFrames
## The pixel placed on the tile's centre; SpriteAnchor.MIDDLE for the middle
@export var sprite_anchor: Vector2i = SpriteAnchor.MIDDLE
## Stats and starting spells
@export var stat_block: StatBlock
