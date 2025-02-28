extends AmbientEffect
class_name AmbientAudioEffect

export(Array) var sounds: Array
export(float) var min_radius: float = 10.0
export(float) var max_radius: float = 100.0
export(float) var min_height: float = 0.0
export(float) var max_height: float = 5.0
export(int) var max_effect_instances: int = 1

var free_effects := []


func _ready():
	for soundPath in sounds:
		var audio_stream = load(soundPath)
		
		for ii in max_effect_instances:
			var oneTimeAudio := OneTimeAudioEffect.new()
			oneTimeAudio.stream = audio_stream
			oneTimeAudio.autoplay = true
			oneTimeAudio.connect("audio_effect_complete", self, "on_audio_effect_complete")
			free_effects.push_back(oneTimeAudio)
		
		free_effects.shuffle()


func _exit_tree():
	for effect in free_effects:
		effect.disconnect("audio_effect_complete", self, "on_audio_effect_complete")
		effect.queue_free()
	
	free_effects.clear()


func get_random_effect() -> OneTimeAudioEffect:
	var effect = null
	
	if not free_effects.empty():
		effect = free_effects.pop_back()

	return effect


func initialize_effect(player):
	pass


func play(localPlayerPos: Vector3):
	.play(localPlayerPos)
	
	var effect := get_random_effect()
	if effect != null:
		#print("Remaining %s free_effects: %d" % [name, free_effects.size()])
		# Randomly position the audio effect around the player
		var soundPosition := localPlayerPos
		var distance := rand_range(min_radius, max_radius)
		var horizontalDirection := Utils.rand_unit_vec3(Vector3(1.0, 0.0, 1.0))
		horizontalDirection = horizontalDirection * distance
		soundPosition += horizontalDirection
		soundPosition.y = rand_range(min_height, max_height)
		
		# Set the position and add the effect to the world
		effect.translation = soundPosition
		add_child(effect)
	elif OS.is_debug_build():
		print("No free audio effect avalible: " + name)


func on_audio_effect_complete(effect):
	remove_child(effect)
	free_effects.push_back(effect)
