class_name MainMenu extends Node
## The menu opened during play, leading to spells, items, stats and the log

enum Option {
    SPELLS,
    ITEMS,
    STATS,
    LOG,
}

const OPTIONS: Array[String] = ["Spells", "Items", "Stats", "Log"]
# Greyed out until they exist
const AVAILABLE: Array[bool] = [false, false, false, true]
const MARGIN: float = 4.0
# Placeholder until there's an opening sound
const OPEN_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_select.ogg")

@export var log_window: LogWindow

@onready var _menu: SelectionMenu = $Menu


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _menu.set_items(OPTIONS, AVAILABLE)
    _menu.chosen.connect(_on_chosen)
    _menu.cancelled.connect(_menu.close)


func _unhandled_input(event: InputEvent) -> void:
    if _menu.visible or get_tree().paused or not event.is_action_pressed(&"open_menu"):
        return
    get_viewport().set_input_as_handled()
    var screen_width: float = get_viewport().get_visible_rect().size.x
    _menu.position = Vector2(screen_width - _menu.size.x - MARGIN, MARGIN)
    Sfx.play(OPEN_SOUND)
    _menu.open()


func _on_chosen(index: int) -> void:
    match index:
        MainMenu.Option.LOG:
            _menu.close()
            log_window.open()
            await log_window.closed
            _menu.open()
