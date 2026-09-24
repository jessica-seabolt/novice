class_name TurnSystem extends RefCounted
## Decides who acts next, and asks each actor to take its turn

var _actors: Array[Player] = []


func add_actor(actor: Player) -> void:
    _actors.append(actor)


## Runs turns forever, one actor at a time
func run() -> void:
    if _actors.is_empty():
        return
    while true:
        for actor: Player in _actors:
            await actor.take_turn()
