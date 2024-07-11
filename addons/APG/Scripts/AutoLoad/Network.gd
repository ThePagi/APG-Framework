#class_name NetworkSingleton
class_name NetworkClass # workaround for not being able to access inner classes using the Autoload name
extends Node
## An autoload script that handles everyting networking related in the APG plugin.
##
## This script handles connections to the signaling server as well as both hosting and joining game rooms.
## It also allows the game client to communicate with the signaling server by sending events.
## The script contains many different signals signifying changes both on the signaling server
## and in the game room. This allows the game client to respond to these changes accordingly
## and eliminates the need to implement basic network behaviors for each minigame separately.

## Emitted when the game client connects to the signaling server.
signal signaling_connected
## Emitted when the game client disconnects from the signaling server.
signal signaling_disconnected
## Emitted when the game client successfuly starts hosting a game room.
signal hosting_started
## Emitted when the game client's attempt to start hosting a game room fails.
signal hosting_failed
## Emitted when the game client stops hosting a game room.
signal hosting_ended
## Emitted when the game client successfully joins a game room.
signal client_started
## Emitted when the game client's attempt to join a game room fails.
signal joining_failed
## Emitted when the game client disconnects from a game room.
signal client_ended
## Emitted after the client with ID equal to [param id] has successfuly joined the game room
## and the host has received their username.
signal client_connected(id)
## Emitted when a new game room starts being hosted by the game client.
## Contains the room's name in [param room_name]. This is emitted right after [signal hosting_started].
signal room_name_changed(room_name)
## Emitted when a new non-null value is assigned to [member current_poll].
## Therefore, it is emitted during a [method start_poll] call when a new poll is created
## and immediately assigned to [member current_poll].
signal poll_created
## Emitted when a queued player takes a previously disconnected player's place in the game
## ([member client_config] must be set to [constant USE_QUEUE]).
## Contains the disconnected player's ID in [param old_id] 
## and the ID of their replacement from the player queue in [param new_id].
signal player_reactivated(old_id, new_id)
## Emitted after [member SceneTree.paused] is set to [code]true[/code] due to the number of active
## players dropping below the value of [member min_players] during an ongoing game.
signal game_paused
## Emited after [member SceneTree.paused] is set to [code]false[/code] due to the number of active
## players reaching at least the value of [member min_players] again during an ongoing game.
signal game_unpaused
## Emitted on the game room's host after a client remotely calls [method returned_to_lobby].
## Contains the calling client's ID in [param id].
signal client_returned_to_lobby(id)
## Emitted when the game client encounters a network related error.
## Contains the error message in [param message].
signal error_occurred(message)
## Emitted upon receiving Google and Twitch account authentication URLs from the signaling server.
## Contains the Google auth URL in [param google] and the Twitch auth URL in [param twitch].
signal auth_links_received(google, twitch)
## Emitted upon successfully logging in to an account on one of the supported streaming platforms.
signal logged_in
## Emitted upon receiving a survey from the signaling server. Contains the survey text in [param msg].
signal survey_received(msg)
## Emitted upon receiving a chat command sent by a stream viewer. Contains the sender's username
## in [param user], the command name in [param cmd], and the command's parameters in [param params].
signal chat_command_received(user, cmd, params)

signal signal_msg_received(msg)

## Message types for events both sent to and received from the signaling server.
enum MsgType {
	DENY, ## General message type for a rejecting response to a request towards the signaling server.
	ACCEPT, ## General message type for an accepting response to a request towards the signaling server.
	JOIN, ## Message type requesting to join a game room.
	STARTHOST, ## Message type requesting to host a game room.
	SESSION, ## Message type for sending a session description to the signaling server.
	CANDIDATE, ## Message type for notifying the signaling server about the creation of an ICE candidate.
	AUTH_LINKS, ## Message type for receiving Google and Twitch account authentization URLs.
	SURVEY, ## Message type for receiving a survey from the signaling server.
	EVENT, ## Message type for sending an event to the signaling server.
	CHAT_COMMAND, ## Message type for receiving a chat command sent by a viewer of the stream.
}

## States of connection to the signaling server.
enum SignalState {
	NONE, ## The game client is not connected to the signaling server. This is the default state.
	LOGGED_IN, ## The game client is connected to the signaling server, but not to a game room.
	TRYING_HOST, ## The game client has sent a request to host a game room and is waiting for a response.
	TRYING_JOIN, ## The game client has sent a request to join a game room and is waiting for a response.
	HOSTING, ## The game client is currently hosting a game room.
	JOINED, ## The game client is currently connected to a game room.
}

## Configuration options for situations where a client connects to the room during an ongoing game.
enum ClientConnectionConfig {
	ALLOW_ALL, ## Clients can join an ongoing game at any time.
	LOBBY_ONLY, ## Clients cannot join an ongoing game. They are placed in the lobby instead.
	USE_QUEUE, ## When clients join an ongoing game, they are placed in the lobby and at the end of the player queue. Once a currently playing client disconnects, the first client in the player queue takes their place.
}

## Constants identifying a client's streaming platform of origin.
enum StreamingPlatform {
	TWITCH,
	YOUTUBE,
}

## Configuration options for situations where a poll ends in a tie.
enum PollTieConfig {
	RANDOM_WINNER, ## Randomly picks one of the poll options with the maximum amount of votes to be the winner.
	HOST_PICKS, ## The game room's host gets to pick one of the options with maximum votes to be the winner.
	EXTEND_TIME, ## The poll continues with extended time. If another tie occurs, behaves like [constant RANDOM_WINNER].
	SECOND_ROUND, ## Another poll starts containing only the poll options with maximum votes. If another tie occurs, behaves like [constant RANDOM_WINNER].
}

## IP address of the signaling server.
@export var signaling_ip: String = "wss://127.0.0.1/ws"
## Signaling server connection state.
var state: SignalState = SignalState.NONE
var auto_reconnect: bool = false
## Configuration for new client connections during an ongoing game.
var client_config: ClientConnectionConfig
## The minimum number of active players required for a game to start or continue running.
## The current number of active players is equal to [code]len(room_data.active_players) + 1[/code]
## since the host is also considered an active player.
var min_players: int = 1

## The player's username from their streaming platform account.
## Its value is set right before [signal logged_in] is emitted.
var username: String
## The name of a game room to host using [method start_host], or to join using [method start_client].
var room_name: String
## Data about the currently hosted game room. Is [code]null[/code] while not hosting a room.
var room_data: RoomData

## The currently relevant [NetworkSingleton.SettingsPoll].
## After a non-null value is assigned, the [signal poll_created] signal is emitted.
var current_poll: SettingsPoll :
	set(poll):
		current_poll = poll
		
		if poll != null:
			poll_created.emit()

var _poll_timer: Timer

var _ws_client := WebSocketPeer.new()
var _ws_state: WebSocketPeer.State = WebSocketPeer.STATE_CLOSED

var _peer_config: Dictionary = {
	"iceServers": [
		{
			"urls": [ "stun:relay.metered.ca:80", ], # One or more STUN servers.
		},
		{
			"urls": [ "turn:relay.metered.ca:80",
			"turn:relay.metered.ca:443",
			"turn:relay.metered.ca:443?transport=tcp" ], # One or more TURN servers.
			"username": "87cfa5dc700e9f214e680891", # Optional username for the TURN server.
			"credential": "rNbPPVTAeojDnaqM", # Optional password for the TURN server.
		},
	],
}
var _peers := WebRTCMultiplayerPeer.new()


func _ready():
	get_tree().set_auto_accept_quit(false)
	multiplayer.multiplayer_peer = null
	
	_poll_timer = Timer.new()
	_poll_timer.one_shot = true
	add_child(_poll_timer, true)
	
	#connect_to_signaling()


func _process(_delta: float):
	_ws_client.poll()
	var new_ws_state: WebSocketPeer.State = _ws_client.get_ready_state()
	
	if new_ws_state == WebSocketPeer.STATE_OPEN:
		while _ws_client.get_available_packet_count():
			var reply: String = _ws_client.get_packet().get_string_from_utf8()
			var msg = JSON.parse_string(reply)
			var to_log = null
			
			if "msg" in msg:
				if msg["msg"] is String:
					to_log = msg["msg"].substr(0, 64).replacen("\n", " | ").replacen("\r", "")
					
					if msg["msg"].length() > 64:
						to_log += "..."
				else:
					to_log = msg["msg"]

			print(name, ": Signal server (", MsgType.keys()[msg["type"]], "): ", to_log)
			signal_msg_received.emit(MsgType.keys()[msg["type"]] + ": " + msg["msg"])
			_manage_signal_msg(msg)
	if _ws_state == new_ws_state:
		return
	_ws_state = new_ws_state
	
	match _ws_state:
		WebSocketPeer.STATE_CONNECTING:
			print(name, ": Connecting to signal server ", signaling_ip)
		WebSocketPeer.STATE_CLOSING:
			print(name, ": Disconnecting from signal server...")
		WebSocketPeer.STATE_CLOSED:
			if multiplayer.connected_to_server.is_connected(_on_connected_to_room):
				multiplayer.connected_to_server.disconnect(_on_connected_to_room)
			
			state = SignalState.NONE
			signaling_disconnected.emit()
			
			if _ws_client.get_close_code() != 1001:
				error_occurred.emit(_ws_client.get_close_reason())
			print(name, ": Disconnected from signal server: ",
				_ws_client.get_close_code(), ", ", _ws_client.get_close_reason())
			await get_tree().create_timer(1.0).timeout
			if auto_reconnect:
				connect_to_signaling()
		WebSocketPeer.STATE_OPEN:
			print(name, ": Connected to signal server.")
			signaling_connected.emit()


func _notification(what: int):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if state == SignalState.JOINED:
			client_ended.emit()
		if state == SignalState.HOSTING:
			hosting_ended.emit()
		state = SignalState.NONE
		
		if _ws_client.get_ready_state() == WebSocketPeer.STATE_OPEN:
			_ws_client.close(1000, "Client application quitting.")
		
		_peers.close()
		await get_tree().create_timer(0.1).timeout
		get_tree().quit() # default behavior


## Attempts to host a room with name [member room_name].
func start_host():
	if state == SignalState.NONE:
		print(name, ": Trying to host while not logged in.")
		error_occurred.emit("Not logged in.")
	elif state != SignalState.LOGGED_IN:
		print(name, ": Trying to host while already a host or a client")
		error_occurred.emit("Already hosting or joining a game.")
	elif _ws_state != WebSocketPeer.STATE_OPEN:
		print(name, ": Trying to host while disconnected from signal server.")
		error_occurred.emit("Not connected to signaling server.")
	else:
		_ws_client.send_text(JSON.stringify({type = MsgType.STARTHOST as int, msg = room_name}))
		state = SignalState.TRYING_HOST
		
		_peers.create_server()
		multiplayer.multiplayer_peer = _peers


## Attempts to join a room with name [member room_name].
func start_client():
	if state == SignalState.NONE:
		print(name, ": Trying to join while not logged in.")
		error_occurred.emit("Not logged in.")
	elif state != SignalState.LOGGED_IN:
		error_occurred.emit("Already hosting or joining a game.")
	elif _ws_state != WebSocketPeer.STATE_OPEN:
		print(name, ": Trying to join while disconnected from signal server.")
		error_occurred.emit("Not connected to signaling server.")
	else:
		state = SignalState.TRYING_JOIN
		_ws_client.send_text(JSON.stringify({type = MsgType.JOIN as int, msg = room_name}))


## Leaves the currently hosted or joined game room.
func leave_room():
	if state == SignalState.HOSTING:
		current_poll = null
		room_data = null
		
		chat_command_received.disconnect(_on_chat_command)
		multiplayer.peer_connected.disconnect(_on_player_connected_to_room)
		multiplayer.peer_disconnected.disconnect(_on_player_disconnected_from_room)
		
		hosting_ended.emit()
	elif state == SignalState.JOINED:
		multiplayer.connected_to_server.disconnect(_on_connected_to_room)
		client_ended.emit()
	
	state = SignalState.NONE
	_peers.close()
	_ws_client.close(1001, "Leaving game room.")
	multiplayer.multiplayer_peer = null


func start_game(game_name: String, detail: String = ""):
	room_data.game_ongoing = true
	current_poll = null
	var event = {
		"event": "game_start",
		"detail": game_name
	}
	send_event(event)

func end_game(detail: String = ""):
	room_data.game_ongoing = false
	room_data.active_players = room_data.player_queue
	room_data.inactive_players.clear()
	room_data.player_queue.clear()
	var event = {
		"event": "game_end",
		"detail": detail
	}
	send_event(event)

func send_event_str(event: String, detail: String = ""):
	send_event({"event": event, "detail": detail})

## Sends the event in [param event] to the signaling server.
func send_event(event_dic: Dictionary):
	var event = JSON.stringify(event_dic)
	print("Sending event: ", event)
	send_msg_to_signal(MsgType.EVENT, event)


## Sends a message of type [enum MsgType] with contents in [param msg] to the signaling server.
func send_msg_to_signal(type: MsgType, msg: String):
	_ws_client.send_text(JSON.stringify({type = int(type), msg = msg, user_id = 0}))


## Sets the name of the game room to host or join to [param new_name].
func set_room(new_name: String):
	room_name = new_name


## Returns [code]true[/code] if the game client is hosting or connected to a game room,
## [code]false[/code] otherwise.
func is_in_room() -> bool:
	return state == SignalState.HOSTING or state == SignalState.JOINED


## Returns a description explaining the meaning of a [enum PollTieConfig] value.
func get_tie_config_description(config: PollTieConfig) -> String:
	match config:
		PollTieConfig.RANDOM_WINNER:
			return "Randomly picks one of the poll options with the maximum amount of votes to be the winner."
		PollTieConfig.HOST_PICKS:
			return "The game room's host gets to pick one of the options with maximum votes to be the winner."
		PollTieConfig.EXTEND_TIME:
			return "The poll continues with extended time. If another tie occurs, behaves like RANDOM WINNER."
		PollTieConfig.SECOND_ROUND:
			return "Another poll starts containing only the poll options with maximum votes. If another tie occurs, behaves like RANDOM WINNER."
		_:
			return ""


## Creates a new [NetworkSingleton.SettingsPoll] value using the provided parameters,
## then starts the poll after a number of seconds specified by [param wait_before_start].
func start_poll(options: Array, length: float, wait_before_start: float, tie_config: PollTieConfig,
		extend_multiplier: float = 1.0):
	if not multiplayer.is_server() or current_poll != null:
		return
	current_poll = SettingsPoll.new(options, _poll_timer)
	await get_tree().create_timer(wait_before_start).timeout
	current_poll.start(length, tie_config, extend_multiplier)


## Informs the room host about the calling client returning to the room's lobby.
## Emits the [signal client_returned_to_lobby] signal on the host.
## Its intended use case is after a client exits a post-game end screen,
## or immediately after a game ends if it has no end screen.
## It is only meant to be called on clients using [code]rpc_id(1)[/code] to remotely call it on the host.
@rpc("any_peer")
func returned_to_lobby():
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	
	if not room_data.game_ongoing or client_config == ClientConnectionConfig.ALLOW_ALL:
		room_data.active_players.append(id)
	else:
		room_data.player_queue.append(id)
	
	client_returned_to_lobby.emit(id)


func _get_peer(id: int) -> WebRTCPeerConnection:
	return _peers.get_peer(id)["connection"] as WebRTCPeerConnection


func connect_to_signaling():
	disconnect_from_signaling()
	_ws_client.connect_to_url(signaling_ip, TLSOptions.client_unsafe())

func disconnect_from_signaling():
	_ws_client.close(1000, "Reconnecting")

func _manage_signal_msg(msg):
	match msg["type"] as MsgType:
		MsgType.DENY:
			if state == SignalState.TRYING_HOST:
				hosting_failed.emit()
			elif state == SignalState.TRYING_JOIN:
				joining_failed.emit()
			error_occurred.emit(msg["msg"])
			state = SignalState.LOGGED_IN
		MsgType.ACCEPT:
			match state:
				SignalState.NONE:
					state = SignalState.LOGGED_IN
					username = msg["msg"]
					logged_in.emit()
				SignalState.TRYING_HOST:
					state = SignalState.HOSTING
					room_name = msg["msg"]
					room_name_changed.emit(room_name)
					room_data = RoomData.new()
					
					chat_command_received.connect(_on_chat_command)
					multiplayer.peer_connected.connect(_on_player_connected_to_room)
					multiplayer.peer_disconnected.connect(_on_player_disconnected_from_room)
					hosting_started.emit()
				SignalState.TRYING_JOIN:
					state = SignalState.JOINED
					_peers.create_client(msg["user_id"])
					multiplayer.multiplayer_peer = _peers
					
					multiplayer.connected_to_server.connect(_on_connected_to_room)
					
					var p := WebRTCPeerConnection.new()
					p.initialize(_peer_config)
					_peers.add_peer(p, 1)
					
					var session: Callable = func(type: String, sdp: String):
						print(name, ": Session desc sending")
						_ws_client.send_text(JSON.stringify(
								{
									type = MsgType.SESSION as int,
									msg = '%'.join([type, sdp]),
								}
						))
						p.set_local_description(type, sdp)
					
					var ice: Callable = func(media: String, index: int, sdp: String):
						print(name, ": Candidate sending")
						_ws_client.send_text(JSON.stringify(
								{
									type = MsgType.CANDIDATE as int,
									msg = '%'.join([media, index, sdp]),
								}
						))
					
					p.session_description_created.connect(session)
					p.ice_candidate_created.connect(ice)
					p.poll()
					
					var res = p.create_offer()
					
					if res != OK:
						print(name, ": Offer error ", res)
						error_occurred.emit("Error ", res, " creating a client offer.")
					client_started.emit()
				SignalState.HOSTING:
					# new client_peer WebRTC complete, client id incoming
					print(name, ": New client id ", msg["msg"])
					#TODO put the client_peer into the high level multiplayer shizzle
				SignalState.JOINED:
					# new client_peer WebRTC complete, client id incoming
					print(name, ": My client id ", msg["msg"])
					#TODO put the client_peer into the high level multiplayer shizzle
		MsgType.SESSION:
			var ses: Array = msg["msg"].split('%', false)
			
			if state == SignalState.HOSTING:
				var p := WebRTCPeerConnection.new()
				p.initialize(_peer_config)
				_peers.add_peer(p, msg["user_id"])
				
				var session: Callable = func(type: String, sdp: String):
					print(name, "(Host): Session desc sending")
					_ws_client.send_text(JSON.stringify(
							{
								type = MsgType.SESSION as int,
								user_id = msg["user_id"],
								msg = '%'.join([type, sdp]),
							}
					))
					p.set_local_description(type, sdp)
				
				var ice: Callable = func(media: String, index: int, sdp: String):
					print(name, "(Host): Candidate sending")
					_ws_client.send_text(JSON.stringify(
							{
								type = MsgType.CANDIDATE as int,
								user_id = msg["user_id"],
								msg = '%'.join([media, index, sdp]),
							}
					))
				
				p.session_description_created.connect(session)
				p.ice_candidate_created.connect(ice)
				p.set_remote_description(ses[0], ses[1])
				_peers.poll()
			elif state == SignalState.JOINED:
				_get_peer(1).set_remote_description(ses[0], ses[1])
		MsgType.CANDIDATE:
			var id: int = 1
			
			if state == SignalState.HOSTING:
				id = msg["user_id"]
			var cand: Array = msg["msg"].split('%', false)
			_get_peer(id).add_ice_candidate(cand[0], int(cand[1]), cand[2])
		MsgType.AUTH_LINKS:
			auth_links_received.emit(msg["google"], msg["twitch"])
		MsgType.SURVEY:
			survey_received.emit(msg["msg"])
		MsgType.CHAT_COMMAND:
			var parts: Array = msg["msg"].split('%', false)
			if len(parts) > 2:
				chat_command_received.emit(parts[0], parts[1], parts.slice(2))
			else:
				chat_command_received.emit(parts[0], parts[1], [])
			
@rpc("any_peer")
func _send_username(username: String):
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	room_data.usernames[id] = username
	client_connected.emit(id)


func _check_game_pause():
	var under_minimum: bool = (
			room_data.game_ongoing and (client_config == ClientConnectionConfig.ALLOW_ALL
			or client_config == ClientConnectionConfig.USE_QUEUE)
			and len(room_data.active_players) + len(room_data.player_queue) + 1 < min_players
	)
	var currently_paused: bool = get_tree().paused
	get_tree().paused = under_minimum
	
	if under_minimum and not currently_paused:
		game_paused.emit()
	elif not under_minimum and currently_paused:
		game_unpaused.emit()


func _reactivate_player():
	if room_data.inactive_players.is_empty() or room_data.player_queue.is_empty():
		return
	var old_id: int = room_data.inactive_players.pop_front()
	var new_id: int = room_data.player_queue.pop_front()
	
	room_data.active_players.erase(old_id)
	room_data.active_players.append(new_id)
	
	player_reactivated.emit(old_id, new_id)


func _on_connected_to_room():
	_send_username.rpc_id(1, username)


func _on_player_connected_to_room(id: int):
	if room_data.game_ongoing:
		match client_config:
			ClientConnectionConfig.ALLOW_ALL:
				room_data.active_players.append(id)
				_check_game_pause()
			ClientConnectionConfig.LOBBY_ONLY:
				room_data.player_queue.append(id)
			ClientConnectionConfig.USE_QUEUE:
				room_data.player_queue.append(id)
				_reactivate_player()
				_check_game_pause()
	else:
		room_data.active_players.append(id)


func _on_player_disconnected_from_room(id: int):
	if (
			room_data.game_ongoing and client_config == ClientConnectionConfig.USE_QUEUE
			and id in room_data.active_players
	):
		room_data.inactive_players.append(id)
		_reactivate_player()
	room_data.player_queue.erase(id)
	room_data.active_players.erase(id)
	
	_check_game_pause()


func _on_chat_command(user: String, cmd: String, params: Array[String]):
	match cmd:
		"vote":
			if (
					current_poll == null or not current_poll.active 
					or len(params) != 1 or not params[0].is_valid_int()
			):
				return
			current_poll.register_vote(int(params[0]), StreamingPlatform.TWITCH, user) # TODO get streaming platform of origin


## Data class holding information about the currently hosted game room.
## The player ID arrays [member active_players], [member inactive_players] and [member player_queue]
## only contain IDs of connected clients, not the room host's ID (which is always [code]1[/code]).
class RoomData extends Object:
	## Equal to [code]true[/code] if a minigame is currently being played in the game room, 
	## [code]false[/code] otherwise.
	var game_ongoing: bool = false
	
	## Maps the IDs of connected clients to their usernames.
	var usernames: Dictionary = {}
	
	## If [member game_ongoing] is [code]false[/code], contains the IDs of all clients connected to the game room.
	## Otherwise contains the IDs of all clients playing a minigame in the game room.
	var active_players: Array = []
	## Only used when [member NetworkSingleton.client_config] is set to 
	## [constant NetworkSingleton.USE_QUEUE].
	## Contains the IDs of all clients that have disconnected from the game room while they were playing
	## a minigame until they are either replaced by a client from [member player_queue], or the minigame ends.
	var inactive_players: Array = []
	## Used when [member NetworkSingleton.client_config] is [b]not[/b] set to 
	## [constant NetworkSingleton.ALLOW_ALL].
	## Accumulates IDs of clients that joined the game room after the currently ongoing minigame has started.
	## If [member NetworkSingleton.client_config] is set to [constant NetworkSingleton.USE_QUEUE],
	## queued clients are able to replace clients from [member inactive_players].
	## When a minigame ends, its contents are swapped with [member active_players].
	var player_queue: Array = []


## Class representing a community poll.
class SettingsPoll extends Object:
	## Emitted when the [method start] method is called.
	signal started
	## Emitted when a cast vote is successfully registered by calling the [method register_vote].
	## A successful registration requires the poll to be active, the option index to be valid,
	## and the vote's sender not having voted previously in the same poll.
	signal vote_registered(index, id)
	## Emitted when the poll ends, providing the winning option's name in [param winner].
	## If the winning option's index is desired instead, it can be read from [member winning_index].
	signal result_decided(winner)
	## Emitted when the poll's [param tie_config] is equal to
	## [constant NetworkSingleton.HOST_PICKS] and a tie occurs.
	signal host_picking
	## Emitted when the poll's [param tie_config] is equal to
	## [constant NetworkSingleton.EXTEND_TIME] and a tie occurs.
	signal time_extended
	## Emitted when the poll's [param tie_config] is equal to
	## [constant NetworkSingleton.SECOND_ROUND] and a tie occurs.
	signal second_round_started
	
	var _votes: Dictionary = {}
	
	## The poll options array.
	var options: Array:
		get:
			return options
	
	## The array of vote totals for each poll option.
	## Indices in this array correspond to option indices in [member options].
	var totals: Array = []:
		get:
			return totals
	
	## Is [code]true[/code] if the poll currently accepts votes, [code]false[/code] otherwise.
	var active: bool = false:
		get: 
			return active
	
	## The index of the winning poll option for the [member options] and [member totals] arrays.
	## If the poll does not have a winner yet, it is equal to [code]-1[/code].
	var winning_index: int = -1:
		get:
			return winning_index
	
	## The timer that counts down the poll's time limit.
	var timer: Timer :
		get:
			return timer
	
	
	func _init(opts: Array, poll_timer: Timer):
		options = opts.duplicate()
		totals.resize(len(opts))
		totals.fill(0)
		
		timer = poll_timer
	
	
	## Starts the poll with time limit equal to [param length] (in seconds), tie configuration
	## equal to [param tie_config], and time limit multiplier for time extension or second round
	## in [param extend_multiplier].
	## If the poll has already started, calls to this method are ignored.
	func start(length: float, tie_config: PollTieConfig, extend_multiplier: float = 1.0):
		if active:
			return
		
		var on_timeout := _create_timeout_callback(length, tie_config, extend_multiplier)
		timer.timeout.connect(on_timeout)
		active = true
		timer.start(length)
		
		started.emit()
	
	
	## Attempts to register a new vote for option [param option], sent by user [param username]
	## from the streaming platform [param platform], optionally with the client ID [param id]
	## if the sender is a connected game client.
	## The vote is ignored if [param option] is an invalid poll option index or
	## if the sender has already voted in this poll.
	func register_vote(option: int, platform: StreamingPlatform, username: String, id: int = -1):
		if not active or option < 0 or option >= len(options) or [platform, username] in _votes:
			return
		_votes[[platform, username]] = option
		totals[option] = totals[option] + 1
		vote_registered.emit(option, id)
	
	
	## Returns the index of the winning poll option for the [member options] and [member totals]
	## arrays. If the poll does not have a winner yet, it returns an empty string instead.
	func get_winning_option() -> String:
		if winning_index == -1:
			return ""
		return options[winning_index]
	
	
	## Makes the poll option with index [param option] the winning option and ends the poll.
	## This method is used by the [constant NetworkSingleton.HOST_PICKS] tie configuration.
	## If [param option] is an invalid option index, the call is ignored.
	func pick_winning_option(option: int):
		if option < 0 or option >= len(options):
			return
		winning_index = option
		result_decided.emit(options[winning_index])
	
	
	## Returns the poll's remaining time in seconds.
	## If [member timer] is [code]null[/code], returns [code]0[/code].
	func get_time_left() -> float:
		if timer == null:
			return 0
		return timer.time_left
	
	
	func _create_timeout_callback(length: float, tie_config: PollTieConfig,
			extend_multiplier: float = 1.0) -> Callable:
		return func():
			active = false
			_disconnect_all(timer.timeout)
			var max_total = totals.max()
			
			if totals.count(max_total) == 1:
				winning_index = totals.find(max_total)
				result_decided.emit(options[winning_index])
				return
			
			match tie_config:
				PollTieConfig.RANDOM_WINNER:
					winning_index = _get_max_total_indices().pick_random()
					result_decided.emit(options[winning_index])
				PollTieConfig.HOST_PICKS:
					host_picking.emit()
				PollTieConfig.EXTEND_TIME:
					var on_timeout := _create_timeout_callback(length,PollTieConfig.RANDOM_WINNER,
							extend_multiplier)
					timer.timeout.connect(on_timeout)
					
					active = true
					timer.start(length * extend_multiplier)
					time_extended.emit()
				PollTieConfig.SECOND_ROUND:
					_votes.clear()
					options = _get_max_total_options()
					totals.resize(len(options))
					totals.fill(0)
					
					var on_timeout := _create_timeout_callback(length, PollTieConfig.RANDOM_WINNER,
							extend_multiplier)
					timer.timeout.connect(on_timeout)
					
					active = true
					timer.start(length * extend_multiplier)
					second_round_started.emit()
	
	
	func _disconnect_all(sig: Signal):
		for connection in sig.get_connections():
			sig.disconnect(connection["callable"])
	
	
	func _get_max_total_indices() -> Array:
		var max_indices: Array = []
		var max_total = totals.max()
		
		for i in range(len(totals)):
			if totals[i] == max_total:
				max_indices.append(i)
		return max_indices
	
	
	func _get_max_total_options() -> Array:
		return _get_max_total_indices().map(func(index: int): return options[index])
