extends Node


var players := {}

var currentGame: GameMode = null
var currentMap = null

const GENERAL_MAP = "map"
const GENERAL_SEED = "shared_seed"

var general = {
	GENERAL_MAP : "",
	GENERAL_SEED : 0
}

var lock := Mutex.new()


func remove_player(playerId: int):
	lock.lock()
	players.erase(playerId)
	lock.unlock()


func get_players() -> Array:
	lock.lock()
	var playersRaw = players.values()
	lock.unlock()
	
	return playersRaw


func get_player(playerId: int) -> PlayerData:
	var data
	
	lock.lock()
	if players.has(playerId):
		data = players[playerId] as PlayerData
	else:
		data = null
	lock.unlock()
	
	return data


func create_new_player_raw_data(playerId: int, platformType: int, playerName: String, playerType: int) -> Dictionary:
	return {
		id = playerId,
		name = playerName,
		lobby_ready = true,
		type = playerType,
		is_host = false,
		platform_type = platformType
	}

func add_player_from_raw_data(newPlayerDictionary: Dictionary) -> bool:
	lock.lock()
	
	var removed := false
	var playerId = newPlayerDictionary.id
	if not self.players.has(playerId):
		var newPlayer := PlayerData.new()
		newPlayer.load(newPlayerDictionary)
		
		self.players[playerId] = newPlayer
		removed = true
	
	lock.unlock()
	
	return removed


func reset():
	lock.lock()
	self.players = {}
	lock.unlock()


func update_general(new_data: Dictionary):
	lock.lock()
	general = new_data
	lock.unlock()


func get_current_player() -> PlayerData:
	var curPlayer
	
	lock.lock()
	var id := get_tree().get_network_unique_id()
	if players.has(id):
		curPlayer = players[id] as PlayerData
	else:
		curPlayer = null
	lock.unlock()
	
	return curPlayer


func get_current_player_type() -> int:
	var curPlayer := get_current_player()
	if curPlayer != null:
		return curPlayer.get_type()
	else:
		return -1


func get_current_player_id() -> int:
	var curPlayer := get_current_player()
	if curPlayer != null:
		return curPlayer.get_id()
	else:
		return -1


func update_player(player_data: PlayerData) -> bool:
	lock.lock()
	var player := get_player(player_data.get_id())
	var updated = player.load(player_data.player_data_dictionary)
	lock.unlock()
	
	return updated
	

func update_player_from_raw_data(player_data_dictionary: Dictionary) -> bool:
	lock.lock()
	
	var updated := false
	
	var playerId = player_data_dictionary.id
	var player := get_player(playerId)
	if player != null:
		updated = player.load(player_data_dictionary)
	lock.unlock()
	
	return updated


func get_host() -> PlayerData:
	lock.lock()
	var host = null
	
	for player in players.values():
		var playerData := player as PlayerData
		
		if playerData.get_is_host() == true:
			host = player
			break
	lock.unlock()
	
	return host
