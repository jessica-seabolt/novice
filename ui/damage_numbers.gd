class_name DamageNumbers extends Node2D
## Red numbers that rise from whoever takes damage

const FONT: FontFile = preload("res://graphics/fonts/dogicapixelbold.otf")
const FONT_SIZE: int = 8
const OUTLINE_SIZE: int = 2
const RISE: float = 10.0
const DURATION: float = 0.6
const WIDTH: float = 24.0
# Starts just above a sprite centred on its tile
const START_OFFSET: Vector2 = Vector2(-12.0, -22.0)

var _settings: LabelSettings = LabelSettings.new()


func _ready() -> void:
    z_index = 10
    _settings.font = FONT
    _settings.font_size = FONT_SIZE
    _settings.font_color = Color.RED
    _settings.outline_size = OUTLINE_SIZE
    _settings.outline_color = Color.BLACK
    SignalBus.entity_damaged.connect(_on_entity_damaged)


func _on_entity_damaged(entity: Entity, amount: int) -> void:
    var number: Label = Label.new()
    number.text = str(amount)
    number.label_settings = _settings
    number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    number.size = Vector2(WIDTH, FONT_SIZE)
    number.position = entity.position + START_OFFSET
    add_child(number)

    var tween: Tween = number.create_tween()
    tween.tween_property(number, "position:y", number.position.y - RISE, DURATION)
    tween.parallel().tween_property(number, "modulate:a", 0.0, DURATION / 2.0).set_delay(
        DURATION / 2.0
    )
    tween.tween_callback(number.queue_free)
