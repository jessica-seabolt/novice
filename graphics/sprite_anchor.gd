class_name SpriteAnchor extends RefCounted
## Anchors a sprite to a specific pixel for precise positioning

## The middle of the first frame, rounded down
const MIDDLE: Vector2i = Vector2i(-1, -1)


static func apply(sprite: AnimatedSprite2D, anchor: Vector2i = SpriteAnchor.MIDDLE) -> void:
    var pixel: Vector2i = anchor
    if anchor == SpriteAnchor.MIDDLE:
        var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
        pixel = Vector2i(floor(frame.get_size()) / 2)
    sprite.centered = false
    sprite.offset = -Vector2(pixel)
