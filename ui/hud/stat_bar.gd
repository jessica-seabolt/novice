class_name StatBar extends HBoxContainer
## A labelled bar that flashes when low and cracks when empty

## Portion of the max at or below which the bar flashes
const LOW_FRACTION: float = 0.25
## Seconds between flashes
const FLASH_INTERVAL: float = 0.25

@export var label: String
@export var full_texture: Texture2D
@export var empty_texture: Texture2D
@export var low_texture: Texture2D

var _low: bool = false
var _flash_time: float = 0.0

@onready var _title: Label = $Title
@onready var _bar: TextureProgressBar = $Bar
@onready var _crack: TextureRect = $Bar/Crack
@onready var _value: Label = $Value


func _ready() -> void:
    _title.text = label
    _bar.texture_under = empty_texture
    _bar.texture_progress = full_texture


func _process(delta: float) -> void:
    if not _low:
        return
    _flash_time += delta
    if _flash_time < FLASH_INTERVAL:
        return
    _flash_time -= FLASH_INTERVAL
    var flashing: bool = _bar.texture_progress == full_texture
    _bar.texture_progress = low_texture if flashing else full_texture


func set_values(current: int, maximum: int) -> void:
    _bar.max_value = maximum
    _bar.value = current
    _value.text = "%d/%d" % [current, maximum]
    _crack.visible = current == 0
    _low = current > 0 and current <= maximum * LOW_FRACTION
    if not _low:
        _bar.texture_progress = full_texture
