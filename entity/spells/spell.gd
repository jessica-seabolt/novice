class_name Spell extends Resource
## Defines a spell's shape, targets, cost, reach, and effects

enum Shape {
    SELF,
    FRONT,
    SPREAD,
    ADJACENT,
    LINE,
    ROOM,
}

enum Targets {
    FOES,
    ALLIES,
}

## Seconds a cast takes
const DURATION: float = 0.3

@export var display_name: String
@export var shape: Spell.Shape = Spell.Shape.FRONT
@export var targets: Spell.Targets = Spell.Targets.FOES
@export_range(0, 100) var cost: int = 1
## Tiles a line travels
@export_range(1, 20) var reach: int = 1
## Applied to each target, in order
@export var effects: Array[Effect] = []


## Whether where the caster faces changes what it covers
func is_aimed() -> bool:
    return shape in [Spell.Shape.FRONT, Spell.Shape.SPREAD, Spell.Shape.LINE]
