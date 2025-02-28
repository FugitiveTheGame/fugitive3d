extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/OQ_ARVROrigin.gd"

signal return_to_main_menu

var standingHeight: float = -1.0
const CROUCH_THRESHOLD := 0.75

onready var camera := $OQ_ARVRCamera as ARVRCamera
onready var player := $Player as Player
onready var locomotion := $Locomotion_Stick
onready var falling := $Feature_Falling
onready var hudCanvas := $OQ_LeftController/VisibilityToggle/HudCanvas
onready var hudVisibilityToggle := $OQ_LeftController/VisibilityToggle
onready var hud := $OQ_LeftController/VisibilityToggle/HudCanvas.find_node("HudContainer", true, false) as Control
onready var fpsLabel := $OQ_LeftController/VisibilityToggle/HudCanvas.find_node("FpsLabel", true, false) as Label
onready var uiRaycast := $OQ_RightController/Feature_UIRayCast
onready var playerCollision := $Feature_PlayerCollision as KinematicBody

onready var inGameMenuHud := hud.find_node("InGameMenuHud", true, false) as WindowDialog
onready var exitGameHud := hud.find_node("ExitGameHud", true, false) as ConfirmationDialog
onready var helpDialog := hud.find_node("HelpDialog", true, false) as WindowDialog

var update_threshold := Threshold.new(Utils.COMMON_NETWORK_UPDATE_THRESHOLD)

const seated_standing_offset_meters := 1.0
const seated_crouching_offset_meters := 0.45
onready var initial_origin := transform.origin as Vector3
onready var initial_shape_origin := player.playerShape.transform.origin as Vector3
var is_standing := true

const CENTER_MIN := 0.20
const CENTER_MAX := 0.40
onready var centerLabel := $OQ_ARVRCamera/CenterLabel
onready var centerIndicator := $Feature_PlayerCollision/CenterIndicator as CSGPrimitive
onready var centerIndicatorMaterial := centerIndicator.material as SpatialMaterial


const DEBOUNCE_THRESHOLD_MS := 100
var debounceBookKeeping = {}
func debounced_button_just_released(button_id) -> bool:
	var debouncedReleased: bool
	
	var justReleased = vr.button_just_released(button_id)
	if justReleased:
		if debounceBookKeeping.has(button_id):
			var lastPressed = debounceBookKeeping[button_id] as int
			var delta = OS.get_system_time_msecs() - lastPressed
			# Debounce and throw away this release
			if delta < DEBOUNCE_THRESHOLD_MS:
				debouncedReleased = false
				#print("Debounced")
			else:
				debounceBookKeeping[button_id] = OS.get_system_time_msecs()
				debouncedReleased = true
				#print("new justRelease")
		else:
			debounceBookKeeping[button_id] = OS.get_system_time_msecs()
			debouncedReleased = true
			#print("first justRelease")
	else:
		debouncedReleased = false
	
	return debouncedReleased


func _enter_tree():
	UserData.connect("user_data_updated", self, "on_user_data_updated")


func _ready():
	player.set_is_local_player()
	
	# Performance tuning for mobile VR clients
	#if Utils.is_quest2():
	#	camera.far = 150.0
	#elif OS.has_feature("mobile"):
	#	camera.far = 100.0
		#hudCanvas.transparent = false
	if OS.has_feature("mobile"):
		camera.far = 100.0
	
	fpsLabel.visible = OS.is_debug_build()
	
	call_deferred("update_standing")


func _exit_tree():
	UserData.disconnect("user_data_updated", self, "on_user_data_updated")


func set_standing_height():
	# Only allow setting standing height during pre-game
	# Other wise you could cheat during the game
	if not player.gameStarted:
		vr.log_info("Standing height set")
		standingHeight = vr.get_current_player_height()
		
		hud.find_node("HeightLabel", true, false).text = "Height: %f m" % standingHeight
	else:
		vr.log_warning("Cannot set standing height while playing")


func process_crouch():
	# Standing mode, crouching is just real crouching
	if is_standing:
		# Movement input
		var curHeight = camera.translation.y
		var curPercent = curHeight / standingHeight
	
		# If the player's is different enough, consider them crouching
		if (curHeight < standingHeight and curPercent < CROUCH_THRESHOLD) or player.car != null:
			player.is_crouching = true
		else:
			player.is_crouching = false
	# Seated mode, crouching is button controlled
	else:
		var wasCrouching := player.is_crouching
		player.is_crouching = vr.button_pressed(vr.BUTTON.LEFT_GRIP_TRIGGER)
		if wasCrouching != player.is_crouching:
			update_head_height()


func _process(delta):
	# Process what to show about the re-center indicator
	var camTrans := playerCollision.translation - camera.translation
	var distFromCenter := Vector2(camTrans.x, camTrans.z).length()
	
	centerLabel.visible = distFromCenter >= CENTER_MAX
	centerIndicator.visible = distFromCenter > CENTER_MIN
	
	var percentVisible := clamp((distFromCenter-CENTER_MIN)/(CENTER_MAX-CENTER_MIN), 0.0, 1.0)
	centerIndicatorMaterial.albedo_color.a = percentVisible


func inject_ptt_action(pressed: bool):
	var event := InputEventAction.new()
	event.action = "push_to_talk"
	event.pressed = pressed
	Input.parse_input_event(event)


func _physics_process(delta):
	# Handle crouching
	process_crouch()
	
	if vr.button_just_pressed(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(true)
	elif debounced_button_just_released(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(false)
	
	# Handle VR controller input
	if debounced_button_just_released(vr.BUTTON.B):
		set_standing_height()
	
	if debounced_button_just_released(vr.BUTTON.ENTER):
		hudVisibilityToggle.visible = true
		if inGameMenuHud.visible:
			inGameMenuHud.hide()
		else:
			inGameMenuHud.popup_centered()
	
	player.sprint = vr.button_pressed(vr.BUTTON.A)
	player.isMoving = locomotion.is_moving
	
	if player.is_sprinting():
		locomotion.move_speed = player.speed_sprint
	elif player.is_crouching:
		locomotion.move_speed = player.speed_crouch
	else:
		locomotion.move_speed = player.speed_walk
	
	if not player.gameEnded and update_threshold.is_exceeded():
		# Our network position is that of our KinematicBody
		var totalTranslation = playerCollision.global_transform.origin
		totalTranslation.y -= totalTranslation.y - global_transform.origin.y
		
		# We need to incorporate head turn into our network rotation
		var totalRotation = rotation
		totalRotation.y += camera.rotation.y
		
		# Seated mode must adjust the position being send out to remote clients
		if not is_standing:
			if player.is_crouching:
				totalTranslation.y += seated_crouching_offset_meters
			
			
		player.rpc_unreliable("network_update", totalTranslation, totalRotation, Vector3(), player.is_crouching, player.isMoving, player.sprint, player.stamina)
	
	if fpsLabel.visible:
		var fps := Engine.get_frames_per_second()
		fpsLabel.text = ("%d fps" % fps)


func _on_InGameMenuHud_about_to_show():
	exitGameHud.hide()
	helpDialog.hide()
	
	uiRaycast.show()


func _on_InGameMenuHud_popup_hide():
	uiRaycast.hide()


func _on_ExitGameHud_return_to_main_menu():
	emit_signal("return_to_main_menu")


func _on_ExitGameHud_on_exit_dialog_show():
	uiRaycast.show()


func _on_ExitGameHud_on_exit_dialog_hide():
	uiRaycast.hide()


func _on_HelpDialog_about_to_show():
	uiRaycast.show()


func _on_HelpDialog_popup_hide():
	uiRaycast.hide()


func _on_InGameMenuHud_show_exit():
	exitGameHud.popup_centered()


func _on_InGameMenuHud_show_help():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode := Maps.get_mode_for_map(mapId)
	helpDialog.showGameMode = mode[Maps.MODE_NAME]
	helpDialog.showControlsFirst = true
	
	helpDialog.popup_centered()


func on_user_data_updated():
	update_standing()


func update_standing():
	if UserData.data.vr_standing != is_standing:
		is_standing = UserData.data.vr_standing
		
		update_head_height()


func update_head_height():
	if not is_standing:
		if player.is_crouching:
			falling.height_offset = seated_crouching_offset_meters
			transform.origin.y = initial_origin.y - seated_crouching_offset_meters
			player.playerShape.transform.origin.y = initial_shape_origin.y + seated_crouching_offset_meters
		else:
			falling.height_offset = seated_standing_offset_meters
			#transform.origin.y = initial_origin.y + seated_standing_offset_meters
			transform.origin.y = initial_origin.y
			player.playerShape.transform.origin.y = initial_shape_origin.y
