class_name SpellSlots extends Control
## While the spell modifier is held, shows which button casts which spell

const BUTTONS: Array[String] = ["A", "B", "X", "Y"]

var _spellbook: Spellbook
var _player_control: PlayerControl

@onready var _content: MarginContainer = $Content
@onready var _rows: VBoxContainer = $Content/Rows


func _ready() -> void:
    hide()


func _process(_delta: float) -> void:
    visible = (
        _spellbook != null
        and not _spellbook.spells.is_empty()
        and not get_tree().paused
        and _player_control.is_awaiting_input()
        and Input.is_action_pressed(&"spell_modifier")
    )
    if not visible:
        return
    for i: int in range(_rows.get_child_count()):
        var affordable: bool = _spellbook.can_cast(_spellbook.spells[i])
        _rows.get_child(i).modulate = Color.WHITE if affordable else SelectionMenu.DISABLED_COLOR


func setup(player: Entity) -> void:
    _spellbook = Spellbook.of(player)
    _player_control = PlayerControl.of(player)
    _spellbook.changed.connect(_refresh)
    _refresh()


func _refresh() -> void:
    for row: Node in _rows.get_children():
        _rows.remove_child(row)
        row.queue_free()
    for i: int in range(mini(_spellbook.spells.size(), BUTTONS.size())):
        var row: Label = Label.new()
        row.text = "%s  %s" % [BUTTONS[i], _spellbook.spells[i].display_name]
        _rows.add_child(row)
    # Grows up and left from its corner
    custom_minimum_size = _content.get_combined_minimum_size()
