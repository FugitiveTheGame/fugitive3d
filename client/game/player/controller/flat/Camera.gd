extends Camera
class_name FpsCamera

onready var fpsController: Spatial = get_parent()

const JOY_THRESHOLD := 0.25

var sensitivity_y := 0.0
var inversion_mult := 1.0
var max_y := 89.0
var mouseLookSensetivityModifier := 1.0

var heldObject: Spatial

func initialize_components():
	sensitivity_y = self.get_parent().Sensitivity_Y
	max_y = self.get_parent().Maximum_Y_Look
	if self.get_parent().Invert_Y_Axis:
		inversion_mult = 1
	else:
		inversion_mult = -1


func _ready():
	self.initialize_components()
	
	mouseLookSensetivityModifier = UserData.data.flat_mouse_sensetivity


func _input(event):
	# Don't process input if we aren't capturing the mouse
	if not fpsController.mouse_captured():
		return
	
	if event is InputEventMouseMotion:
		var rotate_by = inversion_mult * sensitivity_y * mouseLookSensetivityModifier * event.relative.y
		look_vertical(rotate_by)


func _process(delta):
	var look_y_joystick := Input.get_joy_axis(0, JOY_ANALOG_RY)
	if abs(look_y_joystick) > JOY_THRESHOLD:
		var rotate_by = inversion_mult * sensitivity_y * mouseLookSensetivityModifier * look_y_joystick
		look_vertical(rotate_by)


func look_vertical(rotate_by: float):
	if rotate_by == 0.0:
		return 
	if rotate_by >= 0 and self.rotation_degrees.x >= max_y:
		return
	if rotate_by <= 0  and self.rotation_degrees.x <= -max_y:
		return
	
	rotate_x(rotate_by)
	
	if heldObject != null:
		heldObject.rotate_x(rotate_by)
