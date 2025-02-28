extends StateMachine
class_name FugitiveStateMachine

const STATE_CONFIGURING := "configuring"
const STATE_NOT_READY := "not_ready"
const STATE_READY := "ready"
const STATE_COUNTDOWN := "countdown"
const STATE_PLAYING_HEADSTART := "playing_headstart"
const STATE_PLAYING := "playing"
const STATE_GAME_OVER := "game_over"

const TRANS_CONFIGURED := "configured"
const TRANS_READY := "ready"
const TRANS_START_COUNT := "start_count"
const TRANS_GAME_START := "game_start"
const TRANS_COPS_RELEASED := "cops_released"
const TRANS_END_GAME_EARLY := "end_game_early"
const TRANS_END_GAME_ABORT_1 := "end_game_abort_1"
const TRANS_END_GAME_ABORT_2 := "end_game_abort_2"
const TRANS_END_GAME_ABORT_3 := "end_game_abort_3"
const TRANS_END_GAME_ABORT_4 := "end_game_abort_4"
const TRANS_END_GAME := "end_game"


func _ready():
	var configuring := create_state(STATE_CONFIGURING)
	var not_ready := create_state(STATE_NOT_READY)
	var ready := create_state(STATE_READY)
	var countdown := create_state(STATE_COUNTDOWN)
	var playing_head_start := create_state(STATE_PLAYING_HEADSTART)
	var playing := create_state(STATE_PLAYING)
	var game_over := create_state(STATE_GAME_OVER)
	
	create_transition(TRANS_CONFIGURED, configuring, not_ready)
	create_transition(TRANS_READY, not_ready, ready)
	create_transition(TRANS_START_COUNT, ready, countdown)
	create_transition(TRANS_GAME_START, countdown, playing_head_start)
	create_transition(TRANS_COPS_RELEASED, playing_head_start, playing)
	create_transition(TRANS_END_GAME, playing, game_over)
	create_transition(TRANS_END_GAME_EARLY, playing_head_start, game_over)
	create_transition(TRANS_END_GAME_ABORT_1, countdown, game_over)
	create_transition(TRANS_END_GAME_ABORT_2, ready, game_over)
	create_transition(TRANS_END_GAME_ABORT_3, not_ready, game_over)
	create_transition(TRANS_END_GAME_ABORT_4, configuring, game_over)
	
	set_initial_state(configuring)
