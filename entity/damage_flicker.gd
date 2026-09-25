class_name DamageFlicker extends Node
## Blinks the sprite when its entity takes damage

const FLICKERS: int = 4
## Seconds hidden, then shown, per flicker
const INTERVAL: float = 0.05

@export var sprite: CanvasItem

var _tween: Tween


func _ready() -> void:
    Stats.of(get_parent() as Entity).damaged.connect(_on_damaged)


func _on_damaged(_amount: int) -> void:
    if _tween != null:
        _tween.kill()
    sprite.show()
    _tween = create_tween().set_loops(FLICKERS)
    _tween.tween_callback(sprite.hide)
    _tween.tween_interval(INTERVAL)
    _tween.tween_callback(sprite.show)
    _tween.tween_interval(INTERVAL)
