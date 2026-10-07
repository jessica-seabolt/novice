class_name DamageNumbers extends Node2D
## Numbers that rise from whoever takes damage, or green ones for healing

const FONT: FontFile = preload("res://graphics/fonts/PressStart2P-Regular.ttf")
const FONT_SIZE: int = 8
const OUTLINE_SIZE: int = 2
const RISE: float = 10.0
const DURATION: float = 0.6
const WIDTH: float = 24.0
# Starts just above a sprite centred on its tile
const START_OFFSET: Vector2 = Vector2(-12.0, -22.0)

var _damage_settings: LabelSettings = LabelSettings.new()
var _heal_settings: LabelSettings = LabelSettings.new()


func _ready() -> void:
    z_index = 10
    process_mode = Node.PROCESS_MODE_ALWAYS
    for settings: LabelSettings in [_damage_settings, _heal_settings]:
        settings.font = FONT
        settings.font_size = FONT_SIZE
        settings.outline_size = OUTLINE_SIZE
        settings.outline_color = Color.BLACK
    _damage_settings.font_color = Color.RED
    _heal_settings.font_color = Color.GREEN
    SignalBus.entity_damaged.connect(_spawn.bind(_damage_settings))
    SignalBus.entity_healed.connect(_spawn.bind(_heal_settings))


func _spawn(entity: Entity, amount: int, settings: LabelSettings) -> void:
    var number: Label = Label.new()
    number.text = str(amount)
    number.label_settings = settings
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
