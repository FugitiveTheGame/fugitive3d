extends VBoxContainer

signal make_host(playerId)
signal kick_player(playerId)

var playerInfo: PlayerData = null

onready var teamButton := $Controls/TeamButton as OptionButton
var curTeamResolver = null

onready var voipIndicator := $Controls/VoipIndicator


func _ready():
	$Controls/HostMenuButton.get_popup().connect("id_pressed", self, "on_id_pressed")


func populate(player: PlayerData, is_starting: bool, is_host: bool, game_mode: Dictionary):
	playerInfo = player
	var playerId = player.get_id()
	
	var lobbyReady := player.get_lobby_ready()
	
	$Controls/NameLabel.text = player.get_name()
	$Controls/HostIndicator.visible = player.get_is_host()
	
	var iconPath := PlatformTypeUtils.platform_type_icon(player.get_platform_type())
	$Controls/PlatformIndicator.texture = load(iconPath)
	
	curTeamResolver = game_mode[Maps.MODE_TEAM_RESOLVER]
	
	teamButton.clear()
	
	for ii in curTeamResolver.get_num_teams():
		var teamname = curTeamResolver.get_team_name(ii)
		teamButton.add_item(teamname, ii)
	
	var playerType := player.get_type()
	teamButton.selected = playerType
	
	if (is_host or ClientNetwork.is_local_player(playerId)) and not is_starting and lobbyReady:
		teamButton.disabled = false
	else:
		teamButton.disabled = true
	
	$Controls/HostMenuButton.visible = is_host
	$Controls/HostMenuButton.disabled = (playerId == GameData.get_current_player_id() or not lobbyReady or is_starting)
	
	var playerInfoData := GameData.get_player(playerId)

	var score := FugitivePlayerDataUtility.calculate_overall_score(playerInfoData)
	var games := FugitivePlayerDataUtility.get_overall_stat(playerInfoData, FugitivePlayerDataUtility.STAT_GAMES)
	var stats := "Score: %d    |    Games: %d" % [score, games]
	
	if stats.empty():
		$StatsLabel.text = "No games played yet"
	else:
		$StatsLabel.text = stats
	
	# Indicate when a player hasn't returned from the last game yet
	if lobbyReady:
		modulate = Color.white
	else:
		modulate = Color.darkgray


func _on_TeamButton_item_selected(id):
	ServerNetwork.change_player_type(playerInfo.get_id(), id)


func on_id_pressed(id):
	match id:
		0:
			emit_signal("make_host", playerInfo.get_id())
		1:
			emit_signal("kick_player", playerInfo.get_id())


# Override this
func is_voip_active() -> bool:
	return false


func _process(delta):
	voipIndicator.visible = is_voip_active()
