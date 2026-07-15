extends Node

# Nakama settings
const CONNECT = true

const TRY_TO_REFRESH_SESSION = true

const NAKAMA_IP = "api.nakama.powerblock.hackclub.app"
const NAKAMA_PORT = 443
const NAKAMA_HTTP = "https"
const NAKAMA_ENCRYPT_KEY = "fwzxwBJM30XEzHbl"
#const NAKAMA_ENCRYPT_KEY = "fwzxwBJM30XEzHblas"

# Nakama variables
var nakama_client : NakamaClient
var nakama_socket : NakamaSocket
var nakama_session : NakamaSession
var nakama_account : NakamaAPI.ApiAccount
var nakama_user : NakamaAPI.ApiUser

var previous_auth_method : PowerblockAuth.AuthMethods

signal _connected(error: Error)

var status : String
var authenticating : bool = true

var started_auth: bool = false

var server_id : String = ""

func get_nakama_account() -> NakamaAPI.ApiAccount:
	return await nakama_client.get_account_async(nakama_session)

func get_nakama_user() -> NakamaAPI.ApiUser:
	var account : NakamaAPI.ApiAccount = await nakama_client.get_account_async(nakama_session)
	return account.user

func get_avatar_url() -> String:
	var user : NakamaAPI.ApiUser = await get_nakama_user()
	var dirty_url : String = user.avatar_url
	return dirty_url.replace("&amp;", "&")

func clear_tokens():
	if not FileAccess.file_exists("user://nakama_session.cfg"): return ERR_FILE_CANT_OPEN
	
	var config : ConfigFile = ConfigFile.new()
	config.load("user://nakama_session.cfg")
	config.set_value("nakama", "auth_token", "")
	config.set_value("nakama", "refresh_token", "")
	config.save("user://nakama_session.cfg")
	get_tree().quit()

func _process(delta: float) -> void:
	if nakama_session and not authenticating:
		if nakama_session.is_expired():
			nakama_session = await nakama_client.session_refresh_async(nakama_session)
			
			if nakama_session.is_exception():
				PowerblockAuth.authenticate(previous_auth_method)
				nakama_session = await PowerblockAuth.authenticated
				save_auth_keys()

func try_reload_session() -> NakamaSession:
	if not FileAccess.file_exists("user://nakama_session.cfg") or not TRY_TO_REFRESH_SESSION: return null
	
	#push_warning("Trying to reload session")
	
	var config : ConfigFile = ConfigFile.new()
	config.load("user://nakama_session.cfg")
	var session_token = config.get_value("nakama", "auth_token")
	if session_token == null:
		print("Session token null")
		return null
	var session : NakamaSession = nakama_client.restore_session(session_token)
	if session.token == "" or session.token == null:
		print("Session failed refreshing: %s" % session.created)
		return null
	
	push_warning(session)
	
	return session

func save_auth_keys() -> void:
	var config : ConfigFile = ConfigFile.new()
	config.set_value("nakama", "refresh_token", nakama_session.refresh_token)
	config.set_value("nakama", "auth_token", nakama_session.token)
	config.save("user://nakama_session.cfg")

func connect_to_nakama(method: PowerblockAuth.AuthMethods, try_to_refresh : bool = true, dont_try_after_refresh: bool = false) -> Error:
	connect_to_nakama_defered.call_deferred(method, try_to_refresh, dont_try_after_refresh)
	return await _connected

func connect_to_nakama_defered(method: PowerblockAuth.AuthMethods, try_to_refresh : bool = true, dont_try_after_refresh: bool = false) -> void:
	#print("My path: %s, my id: %s" % [get_path(), get_instance_id()])
	
	status = "Connection started..."
	
	if not CONNECT:
		_connected.emit(FAILED)
		status = "CONNECT is false"
		return
	
	status = "Creating client..."
	nakama_client = Nakama.create_client(NAKAMA_ENCRYPT_KEY, NAKAMA_IP, NAKAMA_PORT, NAKAMA_HTTP)
	print("Authenticating...")
	status = "Authenticating session..."
	
	var try_session : NakamaSession = null
	
	if try_to_refresh:
		try_session = try_reload_session()
	
	if try_session == null and not dont_try_after_refresh:
		PowerblockAuth.authenticate(method)
		nakama_session = await PowerblockAuth.authenticated
		print("Session complete")
		if nakama_session == null:
			print("Nakama session is null!")
			_connected.emit(FAILED)
			return
	elif not dont_try_after_refresh:
		nakama_session = try_session
	
	save_auth_keys()
	status = "Saving session tokens..."
	
	nakama_socket = await Nakama.create_socket_from(nakama_client)
	status = "Connecting the socket..."
	var connected : NakamaAsyncResult = await nakama_socket.connect_async(nakama_session)
	if connected.is_exception():
		push_error("Error connection socket: %s" % connected.exception)
		_connected.emit(FAILED)
		return
	
	status = "Getting user data..."
	
	previous_auth_method = method
	
	status = "Connected to Nakama!"
	_connected.emit(OK)
	authenticating = false
	return
