class_name Spell extends Resource
## What a spell covers and what it does to those it reaches

enum Shape {
    SELF,
    FRONT,
    SPREAD,
    ADJACENT,
    LINE,
    ROOM,
}

enum Effect {
    DAMAGE,
    HEAL,
}

## Seconds a cast takes
const DURATION: float = 0.3

@export var display_name: String
@export var shape: Spell.Shape = Spell.Shape.FRONT
@export var effect: Spell.Effect = Spell.Effect.DAMAGE
## Dice rolled
@export_range(1, 10) var power: int = 1
## Tiles a line travels
@export_range(1, 20) var reach: int = 1


## Whether where the caster faces changes what it covers
func is_aimed() -> bool:
    return shape in [Spell.Shape.FRONT, Spell.Shape.SPREAD, Spell.Shape.LINE]
