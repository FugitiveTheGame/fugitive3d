extends Node
class_name VoiceChatReceiver

export(NodePath) var audioPlayerPath: NodePath
onready var audioPlayer := get_node(audioPlayerPath)

onready var opus_decoder := $OpusDecoder

const MAX_CLIPS := 5
var audio_clips := []


func _ready():
	var audioStream := AudioStreamSample.new()
	audioStream.stereo = true
	audioStream.format = AudioStreamSample.FORMAT_16_BITS
	audioStream.mix_rate = 44100
	
	audioPlayer.stream = audioStream
	
	audioPlayer.connect("finished", self, "on_audio_finished")


func _exit_tree():
	audio_clips.clear()


func send_audio(audioData: PoolByteArray):
	rpc("on_receive_audio", audioData)


remote func on_receive_audio(audioData: PoolByteArray):
	if not audioData.empty():
		var pcm_data = opus_decoder.decode(audioData)
		
		if audio_clips.size() < MAX_CLIPS:
			if not pcm_data.empty():
				audio_clips.push_back(pcm_data)
				play_next_clip()
			else:
				push_warning("Decoded PCM data was empty")
		else:
			print("Dropping audio clip, too many in queue already")
	else:
		push_warning("Received empty opus packet.")


func is_playing() -> bool:
	return audioPlayer.playing as bool


func play_next_clip():
	if not is_playing() and not audio_clips.empty():
		var clip = audio_clips.pop_front()
		
		audioPlayer.stream.data = clip
		audioPlayer.play()


func on_audio_finished():
	play_next_clip()
