class_name MainMenu extends Control
## The menu opened on the player's turn, leading to spells, items, stats and the log;
## also opens the log directly

enum Option {
    SPELLS,
    ITEMS,
    STATS,
    LOG,
}

enum ItemOption {
    USE,
    EQUIP,
    DROP,
}

const OPTIONS: Array[String] = ["Spells", "Items", "Stats", "Log"]
const MARGIN: float = 4.0
# Placeholder until there's an opening sound
const OPEN_SOUND: AudioStream = preload("res://audio/sfx/sfx_menu_select.ogg")

@export var log_window: LogWindow

var _spellbook: Spellbook
var _player_control: PlayerControl
var _aim_overlay: AimOverlay
var _inventory: Inventory
# The stack the item action menu is for
var _chosen_stack: ItemStack
# Whether closing the log goes back to this menu
var _log_from_menu: bool = false

@onready var _menu: SelectionMenu = $Menu
@onready var _spell_menu: SelectionMenu = $SpellMenu
@onready var _item_menu: SelectionMenu = $ItemMenu
@onready var _item_action_menu: SelectionMenu = $ItemActionMenu
@onready var _item_info: ItemInfo = $ItemInfo


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _menu.chosen.connect(_on_chosen)
    _menu.cancelled.connect(_menu.close)
    _spell_menu.highlighted.connect(_on_spell_highlighted)
    _spell_menu.chosen.connect(_on_spell_chosen)
    _spell_menu.cancelled.connect(_on_spell_menu_cancelled)
    _item_menu.highlighted.connect(_on_item_highlighted)
    _item_menu.closed.connect(_item_info.hide)
    _item_menu.chosen.connect(_on_item_chosen)
    _item_menu.cancelled.connect(_on_item_menu_cancelled)
    _item_action_menu.chosen.connect(_on_item_action_chosen)
    _item_action_menu.cancelled.connect(_on_item_action_menu_cancelled)


func _unhandled_input(event: InputEvent) -> void:
    if get_tree().paused or not _player_control.is_awaiting_input():
        return
    if event.is_action_pressed(&"open_menu"):
        Sfx.play(OPEN_SOUND)
        _menu.set_enabled(_available_options())
        _menu.select_first()
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
    _inventory = Inventory.of(player)
    _menu.set_items(OPTIONS, _available_options())


## Closes any of its menus that are open, tidying up as cancelling would
func close_all() -> void:
    _log_from_menu = false
    _aim_overlay.preview(null)
    _item_menu.set_process_unhandled_input(true)
    for menu: SelectionMenu in [_menu, _spell_menu, _item_menu, _item_action_menu]:
        if menu.visible:
            menu.close()


# Stats is greyed out until it exists
func _available_options() -> Array[bool]:
    return [not _spellbook.spells.is_empty(), not _inventory.stacks.is_empty(), false, true]


# In the top right corner
func _open(menu: SelectionMenu) -> void:
    menu.position = Vector2(size.x - menu.size.x - MARGIN, MARGIN)
    menu.open()


func _on_chosen(index: int) -> void:
    match index:
        MainMenu.Option.SPELLS:
            var names: Array[String] = []
            var affordable: Array[bool] = []
            for spell: Spell in _spellbook.spells:
                names.append(spell.display_name)
                affordable.append(_spellbook.can_cast(spell))
            _spell_menu.set_items(names, affordable)
            _menu.close()
            _open(_spell_menu)
        MainMenu.Option.ITEMS:
            var labels: Array[String] = []
            var icons: Array[Texture2D] = []
            for stack: ItemStack in _inventory.stacks:
                # Marked up front, where a long name can't cut it off
                var held: bool = _inventory.is_equipped(stack)
                labels.append(("* " if held else "") + stack.get_label())
                icons.append(stack.item.get_icon())
            _item_menu.set_items(labels, [], icons)
            _menu.close()
            _open(_item_menu)
        MainMenu.Option.LOG:
            _menu.close()
            _log_from_menu = true
            log_window.open()
            await log_window.closed
            if _log_from_menu:
                _log_from_menu = false
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


func _on_item_highlighted(index: int) -> void:
    var stack: ItemStack = _inventory.stacks[index]
    _item_info.show_item(stack, _inventory.is_equipped(stack))


func _on_item_chosen(index: int) -> void:
    _chosen_stack = _inventory.stacks[index]
    var held: bool = _inventory.is_equipped(_chosen_stack)
    var use_label: String = _chosen_stack.item.use_label
    var options: Array[String] = [use_label, "Unequip" if held else "Equip", "Drop"]
    var available: Array[bool] = [_inventory.can_use(_chosen_stack), true, _inventory.can_drop()]
    _item_action_menu.set_items(options, available)
    # Beside the item list, which stays up but stops taking input
    _item_menu.set_process_unhandled_input(false)
    _item_action_menu.position = _item_menu.position - Vector2(_item_action_menu.size.x, 0.0)
    _item_action_menu.open()


func _on_item_menu_cancelled() -> void:
    _item_menu.close()
    _menu.open()


func _on_item_action_chosen(index: int) -> void:
    _item_action_menu.close()
    _item_menu.set_process_unhandled_input(true)
    _item_menu.close()
    match index:
        MainMenu.ItemOption.USE:
            _inventory.request(_chosen_stack, Inventory.Action.USE)
        MainMenu.ItemOption.EQUIP:
            if _inventory.is_equipped(_chosen_stack):
                _inventory.unequip()
            else:
                _inventory.equip(_chosen_stack)
        MainMenu.ItemOption.DROP:
            _inventory.request(_chosen_stack, Inventory.Action.DROP)


func _on_item_action_menu_cancelled() -> void:
    _item_action_menu.close()
    _item_menu.set_process_unhandled_input(true)
