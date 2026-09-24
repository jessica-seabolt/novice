class_name TurnSystem extends RefCounted
## Decides who acts next, and asks each actor to take its turn


signal actor_acted(actor: Player)

var _actors: Array[Player] = []
var _running: bool = false


func add_actor(actor: Player) -> void:
    _actors.append(actor)


## Runs turns one actor at a time, until stop() is called
func run() -> void:
    if _actors.is_empty():
        return
    _running = true
    while _running:
        for actor: Player in _actors:
            await actor.take_turn()
            actor_acted.emit(actor)
            if not _running:
                return


## Ends the turn loop once the current actor's turn is over
func stop() -> void:
    _running = false
