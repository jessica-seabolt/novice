class_name Hud extends CanvasLayer
## The player's bars, the latest message, and the full message log

## Seconds the latest message stays on screen
const MESSAGE_DURATION: float = 3.0

var _stats: Stats
var _lines: Array[String] = []

@onready var _health: StatBar = $Bars/Health
@onready var _mana: StatBar = $Bars/Mana
@onready var _popup: Control = $Popup
@onready var _popup_text: Label = $Popup/Text
@onready var _popup_timer: Timer = $Popup/Timer
@onready var _log_window: LogWindow = $LogWindow


func _ready() -> void:
    SignalBus.entity_damaged.connect(_on_entity_damaged)
    SignalBus.entity_defeated.connect(_on_entity_defeated)
    _popup_timer.timeout.connect(_popup.hide)
    _log_window.opened.connect(_hide_popup)


func setup(stats: Stats) -> void:
    _stats = stats
    _stats.changed.connect(_refresh)
    _refresh()


func add_message(text: String) -> void:
    _lines.append(text)
    _log_window.set_lines(_lines)
    _popup_text.text = text
    _popup.show()
    _popup_timer.start(MESSAGE_DURATION)


## The latest message stays on screen
func clear_log() -> void:
    _lines.clear()
    _log_window.set_lines(_lines)


func _hide_popup() -> void:
    _popup.hide()
    _popup_timer.stop()


func _refresh() -> void:
    _health.set_values(_stats.hp, _stats.stat_block.max_hp)
    _mana.set_values(_stats.mana, _stats.stat_block.max_mana)


func _on_entity_damaged(entity: Entity, amount: int) -> void:
    add_message("%s took %d damage" % [entity.display_name, amount])


func _on_entity_defeated(entity: Entity) -> void:
    add_message("%s was defeated" % entity.display_name)
