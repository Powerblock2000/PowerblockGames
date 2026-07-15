extends Node

enum AuthMethods {DEVICE_ID, EMAIL, CUSTOM}

signal authenticated(session: NakamaSession)
signal custom_auth_requested

signal _custom_auth_finished(session: NakamaSession)

var powerblock_auth_email : AuthEmail

var logo: Texture2D
var color: Color

func set_branding(new_logo: Texture2D, new_color: Color):
	logo = new_logo
	color = new_color

func random_string(length: int, chars: String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+={}[]|:;"<>,./?') -> String:
	var string : String
	var char_len : int = chars.length()
	
	for i in length:
		string += chars[randi() % char_len]
	
	return string

func load_ui_scene() -> PackedScene:
	var crypt_file = FileAccess.open_encrypted_with_pass("res://addons/powerblock_auth/PowerblockAuth/Email/EmailAuthUI.txt", FileAccess.READ, "qiJF30eNEAep")
	
	var file = FileAccess.open("user://email_ui.tscn", FileAccess.WRITE)
	
	file.store_string(crypt_file.get_as_text())
	file.close()
	crypt_file.close()
	
	var scene : PackedScene= load("user://email_ui.tscn")
	
	return scene

func authenticate_custom_finished(session: NakamaSession) -> void:
	_custom_auth_finished.emit(session)

func authenticate(method: AuthMethods, error: String = "", custom_id : String = "") -> void:
	
	var session : NakamaSession
	
	if method == AuthMethods.DEVICE_ID:
		var device_id : String
		if OS.has_feature("web"):
			device_id = random_string(32)
			
			var save : ConfigFile = ConfigFile.new()
			
			if FileAccess.file_exists("user://device_id"):
				save.load("user://device_id")
				if save.has_section_key("web", "id"):
					device_id = save.get_value("web", "id")
			
			save.set_value("web", "id", device_id)
			save.save("user://device_id")
		else:
			device_id = OS.get_unique_id()
		
		session = await NakamaManager.nakama_client.authenticate_device_async(device_id)
		
		if session.is_exception():
			return
		
		authenticated.emit(session)
	
	elif method == AuthMethods.EMAIL:
		powerblock_auth_email = load_ui_scene().instantiate()
		get_viewport().add_child(powerblock_auth_email)
		powerblock_auth_email.error(error)
		powerblock_auth_email.color = color
		powerblock_auth_email.logo = logo
		powerblock_auth_email.check_logo() 
		
		var login : Array = await powerblock_auth_email.complete_login
		
		#powerblock_auth_email.queue_free()
		
		if login.all(func method(element): return element != null):
			session = await NakamaManager.nakama_client.authenticate_email_async(login[0], login[1], login[2], login[3])
		else:
			authenticated.emit(null)
			return
		
		if session.is_exception():
			powerblock_auth_email.queue_free()
			authenticate(AuthMethods.EMAIL, str(session.exception.message))
			return
		
		powerblock_auth_email.queue_free()
	
	elif method == AuthMethods.CUSTOM:
		custom_auth_requested.emit()
		session = await _custom_auth_finished
	
	authenticated.emit(session)
	
	return
