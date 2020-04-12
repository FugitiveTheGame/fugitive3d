extends ClientFugitiveGame


func create_player_seeker_node() -> Node:
	var scene = load("res://client/game/mode/fugitive/seeker/flat/FlatSeekerController.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = load("res://client/game/mode/fugitive/hider/flat/FlatHiderController.tscn")
	return scene.instance()