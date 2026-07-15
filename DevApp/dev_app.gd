extends ColorRect

const GAME_SCENE = preload("uid://dljatqihchcg2")

@onready var game_name: LineEdit = $"MarginContainer/TabContainer/New Game/VBoxContainer/GameName"
@onready var game_id: LineEdit = $"MarginContainer/TabContainer/New Game/VBoxContainer/GameID"
@onready var upload: Button = $"MarginContainer/TabContainer/New Game/VBoxContainer/Upload"
@onready var submit: Button = $"MarginContainer/TabContainer/New Game/VBoxContainer/Submit"
@onready var upload_pck_dialog: FileDialog = %UploadPCKDialog
@onready var loading: ColorRect = $Loading
@onready var tab_container: TabContainer = $MarginContainer/TabContainer
@onready var icon_square: LineEdit = $"MarginContainer/TabContainer/New Game/VBoxContainer/IconSquare"
@onready var icon_long: LineEdit = $"MarginContainer/TabContainer/New Game/VBoxContainer/IconLong"
@onready var label: Label = $"MarginContainer/TabContainer/New Game/VBoxContainer/Label"

@onready var regex_snake_case : RegEx = RegEx.create_from_string(r"^[a-z]+(_[a-z]+)*$")

var pck_uploaded : bool = false

var pck_file_path : String

func game_updated(_game_id: String, updated_game_name: String, update_game_icon_long_url: String, update_game_icon_square_url: String, update_is_public: bool, update_pck_path: String) -> void:
	loading.show()
	
	#print("%s, %s, %s, %s, %s, %s" % [_game_id, updated_game_name, update_game_icon_long_url, update_game_icon_square_url, update_is_public, update_pck_path])
	
	var games : Dictionary = await get_games()
	
	var file_name : String = ""
	
	for game in games:
		if game == _game_id:
			file_name = games[game]["file_name"]
	
	if update_pck_path != "":
		pass # TODO add updating .pck
	
	var raw_data : Dictionary = {_game_id: {"game_name": updated_game_name, "file_name": file_name, "public": update_is_public, "icon_square": update_game_icon_square_url, "icon_long": update_game_icon_long_url}}
	
	#print("\n RAW DATA before: **'%s'** \n" % raw_data)
	
	#var data_raw : Dictionary = {_game_id: {"game_name": updated_game_name, "file_name": pck_file_path.get_file(), "public": false, "icon_square": icon_square.text, "icon_long": icon_long}}
	#
	#var games : Dictionary = await get_games()
	if not games.has("Error"):
		for game in games:
			if game != _game_id:
				raw_data[game] = games[game]
	
	#print("\n RAW DATA after: **'%s'** \n" % raw_data)
	
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	
	var read_setting : int = 1
	if update_is_public:
		read_setting = 2
	
	var acks : NakamaAPI.ApiStorageObjectAcks = await NakamaManager.nakama_client.write_storage_objects_async(NakamaManager.nakama_session, [NakamaWriteStorageObject.new("Dev_Games_%s" % user.username, "games", read_setting, 1, JSON.stringify(raw_data), "")])
	
	if acks.is_exception():
		push_error("Failed updating game: %s" % acks.exception.message)
		return
	
	games = await get_games()
	
	for game in %TabContainer.get_children():
		if game.name != "New Game":
			game.queue_free()
	
	for game in await get_games():
		add_game(games[game]["game_name"], game, games[game]["icon_long"], games[game]["icon_square"])
		loading.hide()

#
	#var acks : NakamaAPI.ApiStorageObjectAcks = await NakamaManager.nakama_client.write_storage_objects_async(
		#NakamaManager.nakama_session, 
		#[NakamaWriteStorageObject.new("Dev_Games_%s" % user.username, "games", 2, 1, JSON.stringify(data_raw), "")]
	#)
	#
	#if acks.is_exception():
		#push_error("Failed adding data to nakama: %s" % acks.exception.message)
		#return
	#
	#for game in %TabContainer.get_children():
		#if game.name != "New Game":
			#game.queue_free()
	#
	#for game in await get_games():
		#add_game(games[game]["game_name"], game, games[game]["public"], games[game]["icon_long"], games[game]["icon_square"])
	#
	#loading.hide()


func _process(_delta: float) -> void:
	if pck_uploaded:
		submit.disabled = false
	else:
		submit.disabled = true
	
	if game_name.text != "" and game_id.text !=  "" and icon_long.text != "" and icon_square.text != "":
		var result : RegExMatch = regex_snake_case.search(game_id.text)
		if result != null:
			upload.disabled = false
			return
	
	upload.disabled = true

func _ready() -> void:
	if OS.has_feature("web"):
		$Label.text = "Something went wrong! %s" % r"¯\_(ツ)_/¯"
		get_tree().quit()
		return
	
	var games : Dictionary = await get_games()
	
	if games.has("error"):
		return
	
	for game in games:
		#print(games)
		if games.has(game):
			#print(games[game])
			add_game(games[game]["game_name"], game, games[game]["icon_long"], games[game]["icon_square"])

# "icon_square" "icon_long"

func add_game(_game_name: String, _game_id: String, _long_url: String, _square_url: String) -> void:
	var game : DevPanelGame = GAME_SCENE.instantiate()
	tab_container.add_child(game)
	game.game_name = _game_name
	game.game_id = _game_id
	game.game_icon_long_url = _long_url
	game.game_icon_square_url = _square_url
	
	game.updated_game.connect(game_updated)

func get_games() -> Dictionary:
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	
	var read_object_id : NakamaStorageObjectId = NakamaStorageObjectId.new("Dev_Games_%s" % user.username, "games", user.id)
	var result : NakamaAPI.ApiStorageObjects = await NakamaManager.nakama_client.read_storage_objects_async(NakamaManager.nakama_session, [read_object_id])
	
	push_warning("Result: %s" % result)
	
	if result.objects.size() > 0: 
		return JSON.parse_string(result.objects[0]["value"])
	return {"error": result}

func _on_upload_pressed() -> void:
	upload_pck_dialog.show()
	var path : String = await upload_pck_dialog.file_selected
	pck_uploaded = true
	pck_file_path = path

func get_upload_url(file_name: String) -> String:
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	
	var headers = [
	"Authorization: Bearer " + NakamaManager.nakama_session.token
	]
	
	http.request("http://0.0.0.0:8000/get-upload-url?filename=%s" % file_name.uri_encode(), headers)
	
	var response : Array = await http.request_completed
	
	var body : PackedByteArray = response[3]
	
	var response_code : int = response[1]
	
	if response_code != 200:
		print("failed: %s" % response_code)
		print(body.get_string_from_utf8())
		loading.hide()
		return "Error: %s" % body.get_string_from_utf8()
	
	var json : Dictionary = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		print("Failed")
		loading.hide()
		return "Error: Failed parsing JSON"
	
	var url : String = json["url"]
	return url

func upload_file_to_url(url: String, file_bytes: PackedByteArray) -> Error:
	var request_http : HTTPRequest = HTTPRequest.new()
	add_child(request_http)
	
	var err : Error = request_http.request_raw(url, [], HTTPClient.METHOD_PUT, file_bytes)
	if err != OK:
		print("Error: %s" % error_string(err))
		loading.hide()
		return err
	print("Sent successfully!")
	
	await request_http.request_completed
	return OK

func get_all_games() -> Dictionary:
	var read_object_id : NakamaStorageObjectId = NakamaStorageObjectId.new("game_info", "games", NakamaManager.server_id)
	
	var result : NakamaAPI.ApiStorageObjects = await NakamaManager.nakama_client.read_storage_objects_async(NakamaManager.nakama_session, [read_object_id])
	
	print("\n%s\n" % result)
	
	
	return JSON.parse_string(result.objects[0].value)

func _on_submit_pressed() -> void:
	var all_games : Dictionary = await get_all_games()
	for g in all_games:
		if g == game_id.text:
			label.text = "Game ID already exists!"
			return
	
	loading.show()
	
	var bytes : PackedByteArray = FileAccess.get_file_as_bytes(pck_file_path)
	
	# pck_file_path.get_file()
	
	var url : String = await get_upload_url(pck_file_path.get_file())
	
	await upload_file_to_url(url, bytes)
	
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	
	var data_raw : Dictionary = {game_id.text: {"game_name": game_name.text, "file_name": pck_file_path.get_file(), "public": false, "icon_square": icon_square.text, "icon_long": icon_long.text}}
	
	var games : Dictionary = await get_games()
	if not games.has("error"):
		for game in games:
			data_raw[game] = games[game]
	
	print(r"All Games: " % JSON.stringify(data_raw))
	
	var acks : NakamaAPI.ApiStorageObjectAcks = await NakamaManager.nakama_client.write_storage_objects_async(
		NakamaManager.nakama_session, 
		[NakamaWriteStorageObject.new("Dev_Games_%s" % user.username, "games", 2, 1, JSON.stringify(data_raw), "")]
	)
	
	if acks.is_exception():
		push_error("Failed adding data to nakama: %s" % acks.exception.message)
		return
	
	var payload : Dictionary = {"game_id" = game_id.text}
	var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("add_game_to_search", JSON.stringify(payload))
	
	if response.is_exception():
		push_warning("Error: %s" % response.exception.message)
	
	await get_tree().create_timer(5).timeout
	#var payload : Dictionary = {"username": dev_username.text}
	#var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("give_user_dev", JSON.stringify(payload))
	#if response.is_exception():
		#push_warning("Error: %s" % response.exception.message)
	
	for game in %TabContainer.get_children():
		if game.name != "New Game":
			game.queue_free()
	
	restart_game()

func restart_game() -> void:
	var path : String = OS.get_executable_path()
	
	OS.create_process(path, OS.get_cmdline_args())
	
	get_tree().quit(0)

func _on_help_pressed() -> void:
	OS.shell_open("https://github.com/Powerblock2000/PowerblockGamesDevTools/wiki/Powerblock-Games-Dev-Portal-Docs")
