class_name Hud extends CanvasLayer
## The player's bars, messages, and windows; the game pauses while any window is open

## Seconds the latest message stays on screen
const MESSAGE_DURATION: float = 3.0
## The HUD is laid out at the world's resolution and drawn this many times larger,
## so text has finer pixels than the art
const SCALE: float = 2.0

var _stats: Stats
var _lines: Array[String] = []
var _open_windows: int = 0
# The popup's top edge with one line of text
var _popup_top: float

@onready var _root: Control = $Root
@onready var _health: StatBar = $Root/Bars/Health
@onready var _mana: StatBar = $Root/Bars/Mana
@onready var _popup: Control = $Root/Popup
@onready var _popup_text: Label = $Root/Popup/Text
@onready var _popup_timer: Timer = $Root/Popup/Timer
@onready var _log_window: LogWindow = $Root/LogWindow
@onready var _prompt: Prompt = $Root/Prompt
@onready var _main_menu: MainMenu = $Root/MainMenu
@onready var _spell_slots: SpellSlots = $Root/SpellSlots


func _ready() -> void:
    # Hears Escape while a window has the game paused
    process_mode = Node.PROCESS_MODE_ALWAYS
    _fit_root()
    get_viewport().size_changed.connect(_fit_root)
    SignalBus.entity_damaged.connect(_on_entity_damaged)
    SignalBus.entity_defeated.connect(_on_entity_defeated)
    SignalBus.entity_healed.connect(_on_entity_healed)
    SignalBus.mana_restored.connect(_on_mana_restored)
    SignalBus.spell_cast.connect(_on_spell_cast)
    SignalBus.cast_refused.connect(_on_cast_refused)
    SignalBus.spell_learned.connect(_on_spell_learned)
    SignalBus.spell_strengthened.connect(_on_spell_strengthened)
    SignalBus.item_picked_up.connect(_announce.bind("%s picked up %s"))
    SignalBus.no_room_for.connect(_on_no_room_for)
    SignalBus.item_used.connect(_on_item_used)
    SignalBus.item_dropped.connect(_announce.bind("%s dropped %s"))
    SignalBus.item_equipped.connect(_announce.bind("%s equipped %s"))
    _popup_timer.timeout.connect(_popup.hide)
    _popup_top = _popup.offset_top
    var windows: Array[Node] = [
        _log_window,
        $Root/Prompt/Menu,
        $Root/MainMenu/Menu,
        $Root/MainMenu/SpellMenu,
        $Root/MainMenu/ItemMenu,
        $Root/MainMenu/ItemActionMenu,
    ]
    for window: Node in windows:
        window.opened.connect(_on_window_opened)
        window.closed.connect(_on_window_closed)


# Children see input first, so this only hears Escape when no window took it
func _unhandled_input(event: InputEvent) -> void:
    if _open_windows == 0 or not event.is_action_pressed(&"open_menu"):
        return
    get_viewport().set_input_as_handled()
    close_all()


func setup(player: Entity) -> void:
    _stats = Stats.of(player)
    _stats.changed.connect(_refresh)
    _refresh()
    _main_menu.setup(player)
    _spell_slots.setup(player)


func add_message(text: String) -> void:
    _lines.append(text)
    _log_window.set_lines(_lines)
    _popup_text.text = text
    var extra_lines: int = maxi(0, _popup_text.get_line_count() - 1)
    var line_height: int = (
        _popup_text.get_line_height() + _popup_text.get_theme_constant(&"line_spacing")
    )
    _popup.offset_top = _popup_top - extra_lines * line_height
    _popup.show()
    _popup_timer.start(MESSAGE_DURATION)


## Every window closes as if cancelled
func close_all() -> void:
    _main_menu.close_all()
    _prompt.cancel()
    if _log_window.visible:
        _log_window.close()


## Opens the full log and waits until the player closes it
func show_log() -> void:
    _log_window.open()
    await _log_window.closed


## The chosen option's index, or -1 if cancelled
func ask(question: String, options: Array[String]) -> int:
    return await _prompt.ask(question, options)


## The latest message stays on screen
func clear_log() -> void:
    _lines.clear()
    _log_window.set_lines(_lines)


# Anchors ignore the layer's scale, so the root is sized by hand
func _fit_root() -> void:
    _root.scale = Vector2(SCALE, SCALE)
    _root.size = get_viewport().get_visible_rect().size / SCALE


func _on_window_opened() -> void:
    _open_windows += 1
    get_tree().paused = true
    _popup.hide()
    _popup_timer.stop()


func _on_window_closed() -> void:
    _open_windows -= 1
    get_tree().paused = _open_windows > 0


func _refresh() -> void:
    _health.set_values(_stats.hp, _stats.stat_block.max_hp)
    _mana.set_values(_stats.mana, _stats.stat_block.max_mana)


func _on_entity_damaged(entity: Entity, amount: int) -> void:
    add_message("%s took %d damage" % [entity.display_name, amount])


func _on_entity_defeated(entity: Entity) -> void:
    add_message("%s was defeated" % entity.display_name)


func _on_entity_healed(entity: Entity, amount: int) -> void:
    add_message("%s recovered %d HP" % [entity.display_name, amount])


func _on_mana_restored(entity: Entity, amount: int) -> void:
    add_message("%s recovered %d MP" % [entity.display_name, amount])


func _on_spell_cast(caster: Entity, spell: Spell, _tiles: Array[Vector2i]) -> void:
    if spell != Spellbook.BASIC: # Too common to be worth a message
        add_message("%s cast %s" % [caster.display_name, spell.display_name])


func _on_spell_learned(entity: Entity, spell: Spell) -> void:
    add_message("%s learned %s" % [entity.display_name, spell.display_name])


func _on_spell_strengthened(entity: Entity, spell: Spell) -> void:
    add_message("%s's %s grew stronger" % [entity.display_name, spell.display_name])


func _on_cast_refused(_caster: Entity, _spell: Spell) -> void:
    Sfx.play(SelectionMenu.BAD_SOUND)
    add_message("Not enough MP")


# For messages about an entity and some items
func _announce(entity: Entity, stack: ItemStack, text: String) -> void:
    add_message(text % [entity.display_name, stack.get_label()])


func _on_no_room_for(_entity: Entity, stack: ItemStack) -> void:
    add_message("No room for %s" % stack.get_label())


func _on_item_used(entity: Entity, item: ItemData) -> void:
    add_message("%s used %s" % [entity.display_name, item.display_name])
