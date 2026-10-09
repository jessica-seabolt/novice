class_name ItemInfo extends Control
## A title and description at the bottom of the screen

## Pixels between the frame and the text
const PADDING: Vector2 = Vector2(8.0, 7.0)
const LINE_GAP: float = 2.0

@onready var _name: Label = $Name
@onready var _description: Label = $Description


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    hide()


func show_item(stack: ItemStack, held: bool) -> void:
    show_text(stack.get_label(), ("Held. " if held else "") + stack.item.description)


func show_text(title: String, description: String) -> void:
    _name.text = title
    _description.text = description
    _description.visible = not _description.text.is_empty()
    var bottom: float = _place(_name, PADDING.y)
    if _description.visible:
        bottom = _place(_description, bottom + LINE_GAP)
    offset_top = offset_bottom - (bottom + PADDING.y)
    show()


# Returns where the label ends
func _place(label: Label, top: float) -> float:
    label.position = Vector2(PADDING.x, top)
    label.size.x = size.x - PADDING.x * 2.0
    var line_height: int = label.get_line_height() + label.get_theme_constant(&"line_spacing")
    label.size.y = label.get_line_count() * line_height
    return top + label.size.y
