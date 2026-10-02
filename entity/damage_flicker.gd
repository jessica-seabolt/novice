class_name DamageFlicker extends Node
## Blinks the sprite when its entity takes damage, and blinks it away when defeated

const FLICKERS: int = 4
## Seconds hidden, then shown, per flicker
const INTERVAL: float = 0.05

@export var sprite: CanvasItem

var _tween: Tween


## Null if the entity doesn't flicker
static func of(entity: Entity) -> DamageFlicker:
    return entity.get_node_or_null("DamageFlicker") as DamageFlicker


func _ready() -> void:
    var entity: Entity = get_parent() as Entity
    Stats.of(entity).damaged.connect(_on_damaged)
    entity.placed.connect(_on_placed)


## Blinks, then leaves the sprite hidden
func vanish() -> void:
    _flicker()
    await _tween.finished
    sprite.hide()


func _on_damaged(_amount: int) -> void:
    _flicker()


func _on_placed() -> void:
    if _tween != null:
        _tween.kill()
    sprite.show()


func _flicker() -> void:
    if _tween != null:
        _tween.kill()
    sprite.show()
    _tween = create_tween().set_loops(FLICKERS).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    _tween.tween_callback(sprite.hide)
    _tween.tween_interval(INTERVAL)
    _tween.tween_callback(sprite.show)
    _tween.tween_interval(INTERVAL)
