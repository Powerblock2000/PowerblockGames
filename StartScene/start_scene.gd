extends Control

signal read_to_change
signal _auth_complete(claims: Dictionary)

const POWERBLOCK_GAMES_LOGO_LARGE_WHITE = preload("uid://21gn4e20jetc")
const ONBOARDING_SCENE = preload("uid://bksewkwq1oepq")

@onready var connected: SlideInText = $Connected
@onready var cant_connect: SlideInText = $CantConnect

var retry_times : int = 3

func _ready() -> void:
	PowerblockAuth.set_branding(null, Color("89FC00"))
	await get_tree().create_timer(3).timeout
	PowerblockAuth.custom_auth_requested.connect(custom_auth)
	connect_to_server.call_deferred()

func custom_auth() -> void:
	var login_id: String = str(PbUtils.random_string(32)).uri_encode()
	PbUtils.random_string(8, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	var url = "https://auth.powerblockgames.powerblock.hackclub.app/auth/hackclub?login_id=%s" % login_id
	OS.shell_open(url)
	var claims : Dictionary = await poll_backend(login_id)
	
	var token : String = claims["token"]
	
	var vars : Dictionary = {
		"token" : token
	}
	
	var custom_id : String = PbUtils.random_string(8, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
	
	print("Custom id: %s" % custom_id)
	var session : NakamaSession = await NakamaManager.nakama_client.authenticate_custom_async(custom_id, null, true, vars)
	if session.is_exception():
		print("An error occurred: %s" % session)
		return
	print("Successfully authenticated: %s" % session)
	
	PowerblockAuth.authenticate_custom_finished(session)

func poll_backend(login_id: String) -> Dictionary:
	var url = "https://auth.powerblockgames.powerblock.hackclub.app/auth/status?login_id=%s" % login_id
	
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	var error : Error = http.request(url)
	if error != OK:
		http.queue_free()
		return await poll_backend(login_id)
	var result : Array = await http.request_completed
	var body : Dictionary = JSON.parse_string((result[3] as PackedByteArray).get_string_from_utf8()) ## TODO FIX ON WEB
	http.queue_free()
	
	if body.has("completed") and body["completed"]:
		print(body)
		return body
	
	await get_tree().create_timer(1).timeout
	return await poll_backend(login_id)

func connect_to_server(try_to_refresh: bool = true):
	var error : Error = await NakamaManager.connect_to_nakama(PowerblockAuth.AuthMethods.CUSTOM, try_to_refresh)
	
	push_warning(error)
	
	if error != OK and retry_times > 0 and retry_times != 1:
		push_warning("Couldnt connect, retrying")
		retry_times -= 1
		connect_to_server(false)
		return
	elif error != OK:
		push_warning("Couldnt connect")
		cant_connect.show()
		return
	connected.show()
	
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	
	var metadata : Dictionary = JSON.parse_string(user.metadata)
	
	if OS.has_feature("DevApp") and metadata.has("developer"):
		if metadata.get("developer") == true:
			get_tree().change_scene_to_file("res://DevApp/DevApp.tscn")
			queue_free()
			return
		else:
			print("Developer not approved!")
	elif OS.has_feature("DevApp"):
		get_tree().quit(-1)
		return
	
	if user.display_name == "": #or true:
		print("Onboarding!")
		var onboarding : Onboarding = ONBOARDING_SCENE.instantiate()
		get_viewport().add_child(onboarding)
		await onboarding.onboard()
	
	read_to_change.emit()

func _on_issues_pressed() -> void:
	OS.shell_open("https://github.com/Powerblock2000/PowerblockGames/issues")
