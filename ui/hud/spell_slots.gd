class_name SpellSlots extends Control
## While the spell modifier is held, shows which button casts which spell

const BUTTONS: Array[String] = ["A", "B", "X", "Y"]

var _spellbook: Spellbook

@onready var _content: MarginContainer = $Content
@onready var _text: Label = $Content/Text


func _ready() -> void:
    hide()


func _process(_delta: float) -> void:
    visible = (
        _spellbook != null
        and not _spellbook.spells.is_empty()
        and not get_tree().paused
        and Input.is_action_pressed(&"spell_modifier")
    )


func setup(spellbook: Spellbook) -> void:
    _spellbook = spellbook
    var lines: Array[String] = []
    for i: int in range(mini(_spellbook.spells.size(), BUTTONS.size())):
        lines.append("%s  %s" % [BUTTONS[i], _spellbook.spells[i].display_name])
    _text.text = "\n".join(lines)
    # Grows up and left from its corner
    custom_minimum_size = _content.get_combined_minimum_size()
