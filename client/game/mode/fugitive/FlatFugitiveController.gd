extends "res://client/game/player/controller/flat/FlatPlayerController.gd"

onready var hud := $HudCanvas/HudContainer/PregameHud
onready var overviewMapHud := $HudCanvas/HudContainer/OverviewMapHud

export(NodePath) var use_button_path: NodePath
onready var use_button := get_node(use_button_path) as TouchScreenButton

export(NodePath) var car_horn_button_path: NodePath
onready var car_horn_button := get_node(car_horn_button_path) as TouchScreenButton


# Allow child classes to override this functionality
func show_map(show: bool):
	overviewMapHud.visible = show


func _input(event):
	if not player.gameStarted and event.is_action_released("flat_player_jump"):
		player.set_ready()
	
	if event.is_action_released("flat_player_use"):
		var player := get_player()
		if player != null and player.car == null:
			var cars := get_tree().get_nodes_in_group(Groups.CARS)
			for car in cars:
				if car.enterArea.overlaps_body(player.playerBody):
					car.request_enter_car(player)
					break
		else:
			player.car.request_exit_car(player)
	
	if event.is_action_released("flat_car_horn"):
		if player.car != null and player.car.is_driver(player.id):
			player.car.honk_horn()


func _process(delta):
	self.allowMovement = not player.frozen and player.car == null and not player.gameEnded
	
	# Stick the user's butt in their seat!
	if player.car != null:
		var seat = player.car.find_players_seat(player.id)
		if seat != null:
			global_transform.origin = seat.global_transform.origin
	
	show_map( Input.is_action_pressed("flat_fugitive_map") )
	
	# Only allow the driver to control the car
	if player.car != null and player.car.is_driver(player.id):
		var forward := Input.is_action_pressed("flat_player_up") or (virtual_joysticks.left_output.y > 0.0) as bool
		var backward := Input.is_action_pressed("flat_player_down") or (virtual_joysticks.left_output.y < 0.0) as bool
		var left := Input.is_action_pressed("flat_player_left") or (virtual_joysticks.left_output.x < 0.0) as bool
		var right := Input.is_action_pressed("flat_player_right") or (virtual_joysticks.left_output.x > 0.0) as bool
		var breaking := Input.is_action_pressed("flat_player_jump")
		
		player.car.process_input(forward, backward, left, right, breaking, delta)
		
	if OS.has_touchscreen_ui_hint():
		if player.car != null:
			use_button.show()
			
			crouch_button.hide()
			sprint_button.hide()
			
			if player.car.is_driver(player.id):
				car_horn_button.show()
			else:
				car_horn_button.hide()
		else:
			car_horn_button.hide()
			
			crouch_button.show()
			sprint_button.show()
			
			if get_nearest_car() != null:
				use_button.show()
			else:
				use_button.hide()


func get_nearest_car():
	var closestCar = null
	
	var cars = get_tree().get_nodes_in_group(Groups.CARS)
	for car in cars:
		if car.enterArea.overlaps_body(player.playerBody):
			closestCar = car
			break
	
	return closestCar


func on_car_entered(car):
	update_camera_to_head()


func on_car_exited(car):
	update_camera_to_head()


func car_rotate(angle: float):
	rpc_unreliable("on_car_rotate", angle)


remotesync func on_car_rotate(angle: float):
	rotate_y(angle)


func on_state_not_ready():
	$HudCanvas/HudContainer/PregameHud.show()
	$HudCanvas/HudContainer/PregameHud.show_not_ready()


func on_state_ready():
	$HudCanvas/HudContainer/PregameHud.show_ready()


func on_state_countdown():
	$HudCanvas/HudContainer/PregameHud.show_start_timer()


func on_state_headstart():
	$HudCanvas/HudContainer/PregameHud.show_headstart_timer()


func on_state_playing():
	$HudCanvas/HudContainer/PregameHud.start_play_phase()


func on_state_game_over():
	$HudCanvas/HudContainer/EndGameHud.team_won( GameData.currentGame.winningTeam )
	release_mouse()
	# Hide the sticks on mobile clients so they can interact with the end-game hud
	virtual_joysticks.hide()


func _notification(what):
	# We don't want the mouse captured in the end-game state
	# If they alt-tab out and back in, we need to re-release it
	if what == MainLoop.NOTIFICATION_WM_FOCUS_IN and player != null and player.gameEnded:
		call_deferred("release_mouse")


func _on_InGameMenuHud_popup_hide():
	if not player.gameEnded:
		._on_InGameMenuHud_popup_hide()


func _on_ExitGameHud_on_exit_dialog_hide():
	if not player.gameEnded:
		._on_ExitGameHud_on_exit_dialog_hide()


func _on_HelpDialog_popup_hide():
	if not player.gameEnded:
		._on_HelpDialog_popup_hide()
