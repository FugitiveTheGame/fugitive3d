extends "BaseNetwork.gd"

const SERVER_ID := 1
const SERVER_REPOSITORY_URL := "http://repository.fugitivethegame.online:8080"

func _player_connected(id):
	print("Player connected: " + str(id))


func _player_disconnected(id):
	._player_disconnected(id)
	
	# If there are any players left, pick the first one
	# and make them host
	if not GameData.players.empty():
		var newHost = GameData.players.values().front()
		make_host(newHost[GameData.PLAYER_ID])


# Called by clients when they connect
func register_self(playerId: int, playerName: String):
	rpc_id(SERVER_ID, "on_register_self", playerId, playerName)


remote func on_register_self(playerId, playerName):
	var playerType: int
	if GameData.players.size() == 0:
		playerType = GameData.PlayerType.Seeker
	else:
		playerType = GameData.PlayerType.Hider
	
	var playerData = GameData.create_new_player(playerId, playerName, playerType)
	
	# Register this client with the server
	ClientNetwork.on_register_player(playerData)
	
	# Register the new player with all existing clients
	for curPlayerId in GameData.players:
		ClientNetwork.register_player(curPlayerId, playerData)
	
	# Catch the new player up on who is already here
	for curPlayerId in GameData.players:
		if curPlayerId != playerId:
			var player = GameData.players[curPlayerId]
			ClientNetwork.register_player(playerId, player)
	
	# If this is the first player to connect
	# make them the host
	if GameData.players.size() == 1:
		make_host(playerId)


func make_host(playerId):
	var playerInfo = GameData.players[playerId]
	playerInfo[GameData.PLAYER_HOST] = true
	ClientNetwork.update_player(playerInfo)


func is_hosting() -> bool:
	if get_tree().network_peer != null and get_tree().network_peer.get_connection_status() != 0: # NetworkedMultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED
		return true
	else:
		return false


func host_game(port: int = SERVER_PORT) -> bool:
	# Clear out any old state
	reset_network()
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(port, MAX_PLAYERS)
	if result == OK:
		get_tree().set_network_peer(peer)
		
		get_tree().connect("network_peer_connected", self, "_player_connected")	
		
		print("Server started.")
		return true
	else:
		print("Failed to host game: %d" % result)
		return false
