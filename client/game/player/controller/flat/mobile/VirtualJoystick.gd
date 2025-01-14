extends Control
class_name VirtualJoysticks

export(float, 0.0, 1.0, 0.001) var left_dead_zone := 0.40
export(float, 0.0, 1.0, 0.001) var right_dead_zone := 0.40

onready var baseLeft := $BaseLeft as TextureRect
onready var baseRight := $BaseRight as TextureRect

onready var stickLeft := $BaseLeft/Stick as TextureRect
onready var stickRight := $BaseRight/Stick as TextureRect


var left_finger_index := -1
var right_finger_index := -1

var left_initial_position: Vector2
var right_initial_position: Vector2

var left_move_radius: float
var right_move_radius: float

var left_output := Vector2()
var right_output := Vector2()


func _ready():
	left_initial_position = stickLeft.rect_position
	right_initial_position = stickRight.rect_position
	
	left_move_radius = get_min_size(baseLeft.rect_size) / 2.0
	right_move_radius = get_min_size(baseRight.rect_size) / 2.0
	
	visible = OS.has_touchscreen_ui_hint()


func get_min_size(rect: Vector2) -> float:
	return min(rect.x, rect.y)


func _gui_input(event):
	handle_left(event)
	handle_right(event)
	
	if event is InputEventScreenDrag:
		if event.index == left_finger_index:
			left_output = update_stick(stickLeft, baseLeft, left_move_radius, left_initial_position, event.position, left_dead_zone)
		elif event.index == right_finger_index:
			right_output = update_stick(stickRight, baseRight, right_move_radius, right_initial_position, event.position, right_dead_zone)


func update_stick(stick: TextureRect, base: TextureRect, radius: float, centerPosition: Vector2, newPosition: Vector2, deadZone: float) -> Vector2:
	var stick_center := newPosition - base.rect_position - (stick.rect_size / 2.0)
	
	var output := Vector2()
	if centerPosition.distance_to(stick_center) > radius:
		var restricted := centerPosition + (stick_center - centerPosition).normalized() * radius
		output = restricted - centerPosition
		stick.set_position(restricted)
	else:
		output = stick_center - centerPosition
		stick.set_position(stick_center)
	
	output = output / radius
	
	if output.x < deadZone and output.x > -deadZone:
		output.x = 0.0
	
	if output.y < deadZone and output.y > -deadZone:
		output.y = 0.0
	else:
		output.y *= -1.0
	
	return output


func _unhandled_input(event):
	handle_left(event)
	handle_right(event)


func _on_BaseLeft_gui_input(event):
	handle_left(event)


func _on_BaseRight_gui_input(event):
	handle_right(event)


func handle_left(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if baseLeft.get_rect().has_point(event.position):
				if left_finger_index == -1:
					left_finger_index = event.index
					print("capture LEFT")
		elif event.index == left_finger_index:
			release_left()
	elif event is InputEventScreenDrag:
		if left_finger_index == -1 and baseLeft.get_rect().has_point(event.position):
			left_finger_index = event.index
			print("capture LEFT")


func handle_right(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if baseRight.get_rect().has_point(event.position):
				if right_finger_index == -1:
					right_finger_index = event.index
					print("capture RIGHT")
		elif event.index == right_finger_index:
			release_right()
	elif event is InputEventScreenDrag:
		if right_finger_index == -1 and baseRight.get_rect().has_point(event.position):
			right_finger_index = event.index
			print("capture RIGHT")


func release_left():
	if left_finger_index > -1:
		print("release LEFT")
		left_finger_index = -1
		left_output = Vector2()
		stickLeft.rect_position = left_initial_position


func release_right():
	if right_finger_index > -1:
		print("release RIGHT")
		right_finger_index = -1
		right_output = Vector2()
		stickRight.rect_position = right_initial_position
