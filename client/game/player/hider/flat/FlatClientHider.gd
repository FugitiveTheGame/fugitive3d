extends "res://client/game/player/controller/flat/FlatPlayerController.gd"

func _ready():
	$Player.set_is_local_player()


func _process(delta):
	if player is Hider:
		allowMovement = not player.frozen
