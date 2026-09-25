extends Node
## Plays one-shot sound effects, including while the game is paused

const PLAYERS: int = 4

var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for _i: int in range(PLAYERS):
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)


## Quick sounds overlap rather than cut each other off
func play(stream: AudioStream) -> void:
    var player: AudioStreamPlayer = _players[_next]
    _next = (_next + 1) % PLAYERS
    player.stream = stream
    player.play()
