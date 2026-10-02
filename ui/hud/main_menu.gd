class_name MainMenu extends Node
## The menu opened on the player's turn, leading to spells, items, stats and the log;
## also opens the log directly

enum Option {
    SPELLS,
    ITEMS,
    STATS,
    LOG,
}

const OPTIONS: Array[String] = ["Spells", "Items", "Stats", "Log"]
const MARGIN: float = 4.0
# Placeholder until there's an opening sound
const OPEN_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_select.ogg")

@export var log_window: LogWindow

var _spellbook: Spellbook
var _player_control: PlayerControl
var _aim_overlay: AimOverlay

@onready var _menu: SelectionMenu = $Menu
@onready var _spell_menu: SelectionMenu = $SpellMenu


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _menu.chosen.connect(_on_chosen)
    _menu.cancelled.connect(_menu.close)
    _spell_menu.highlighted.connect(_on_spell_highlighted)
    _spell_menu.chosen.connect(_on_spell_chosen)
    _spell_menu.cancelled.connect(_on_spell_menu_cancelled)


func _unhandled_input(event: InputEvent) -> void:
    if get_tree().paused or not _player_control.is_awaiting_input():
        return
    if event.is_action_pressed(&"open_menu"):
        Sfx.play(OPEN_SOUND)
        _open(_menu)
    elif event.is_action_pressed(&"toggle_log"):
        log_window.open()
    else:
        return
    get_viewport().set_input_as_handled()


func setup(player: Entity) -> void:
    _spellbook = Spellbook.of(player)
    _player_control = PlayerControl.of(player)
    _aim_overlay = AimOverlay.of(player)
    var names: Array[String] = []
    for spell: Spell in _spellbook.spells:
        names.append(spell.display_name)
    _spell_menu.set_items(names)
    # Greyed out until they exist
    var available: Array[bool] = [not names.is_empty(), false, false, true]
    _menu.set_items(OPTIONS, available)


# In the top right corner
func _open(menu: SelectionMenu) -> void:
    var screen_width: float = get_viewport().get_visible_rect().size.x
    menu.position = Vector2(screen_width - menu.size.x - MARGIN, MARGIN)
    menu.open()


func _on_chosen(index: int) -> void:
    match index:
        MainMenu.Option.SPELLS:
            var affordable: Array[bool] = []
            for spell: Spell in _spellbook.spells:
                affordable.append(_spellbook.can_cast(spell))
            _spell_menu.set_enabled(affordable)
            _menu.close()
            _open(_spell_menu)
        MainMenu.Option.LOG:
            _menu.close()
            log_window.open()
            await log_window.closed
            _menu.open()


func _on_spell_highlighted(index: int) -> void:
    _aim_overlay.preview(_spellbook.spells[index])


func _on_spell_chosen(index: int) -> void:
    _aim_overlay.preview(null)
    _spell_menu.close()
    _spellbook.request(_spellbook.spells[index])


func _on_spell_menu_cancelled() -> void:
    _aim_overlay.preview(null)
    _spell_menu.close()
    _menu.open()
