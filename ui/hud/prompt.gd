class_name Prompt extends Control
## A question at the bottom of the screen, with options to choose from above it

signal answered(index: int)

@onready var _question: Control = $Question
@onready var _text: Label = $Question/Text
@onready var _menu: SelectionMenu = $Menu


func _ready() -> void:
    hide()
    _menu.chosen.connect(answered.emit)
    _menu.cancelled.connect(answered.emit.bind(-1))


## The chosen option's index, or -1 if cancelled
func ask(question: String, options: Array[String]) -> int:
    _text.text = question
    _menu.set_items(options)
    show()
    _menu.position = Vector2(
        size.x - _menu.size.x - 4.0, _question.position.y - _menu.size.y - 2.0
    )
    _menu.open()
    var index: int = await answered
    _menu.close()
    hide()
    return index
