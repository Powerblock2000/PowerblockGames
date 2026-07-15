extends Control

const START_SCENE = preload("uid://b8lqg1dg4kqcb")
const SETTINGS_SCENE = preload("uid://bhf6iwskauuab")
const LOAD_GAME_SCENE = preload("uid://c8ijnr8vged6w")

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var search_bar: LineEdit = $PanelContainer/Control/MarginContainer/TabContainer/Home/ScrollContainer/VBoxContainer/HBoxContainer/SearchBar
@onready var search: Button = $PanelContainer/Control/MarginContainer/TabContainer/Home/ScrollContainer/VBoxContainer/HBoxContainer/Search

signal connected
signal loaded

var friends_ready : bool = false:
	set(value):
		friends_ready = value
		push_warning("FRIENDS READY")
var home_ready : bool = false:
	set(value):
		home_ready = value
		push_warning("HOME READY")
var loaded_emited : bool = false

func _process(_delta: float) -> void:
	if friends_ready and home_ready and not loaded_emited:
		loaded_emited = true
		print("Loaded emitted")
		loaded.emit()

func get_featured_games() -> Dictionary:
	var read_object_id : NakamaStorageObjectId = NakamaStorageObjectId.new("game_info", "featured_games", NakamaManager.server_id)
	var result : NakamaAPI.ApiStorageObjects = await NakamaManager.nakama_client.read_storage_objects_async(NakamaManager.nakama_session, [read_object_id])
	
	push_warning("Result: %s" % result)
	
	if result.objects.size() > 0: 
		return JSON.parse_string(result.objects[0]["value"])
	return {"error": result}

func _ready() -> void:
	ready_deffered.call_deferred()

func ready_deffered() -> void:
	var start : ColorRect = START_SCENE.instantiate()
	get_viewport().add_child(start)
	await start.read_to_change
	connected.emit()
	print("Waiting...")
	
	var featured_games : Dictionary = await get_featured_games()
	if featured_games.has("error"):
		print(featured_games["error"])
		return
	
	for game in featured_games:
		var game_tex_but : FeaturedGameButton = get_node("PanelContainer/Control/MarginContainer/TabContainer/Home/ScrollContainer/VBoxContainer/HeroImages/HBoxContainer/%s" % game)
		
		game_tex_but.texture_normal = await PbUtils.get_image_from_url(featured_games[game]["img"])
		get_node("PanelContainer/Control/MarginContainer/TabContainer/Home/ScrollContainer/VBoxContainer/HeroImages/HBoxContainer/%s/ColorRect" % game).hide()
		game_tex_but.game_name = featured_games[game]["name"]
		game_tex_but.tooltip_text = featured_games[game]["name"]
		game_tex_but.pressed.connect(featured_game_pressed.bind(game_tex_but.game_name))
	
	home_ready = true
	
	await loaded
	print("---LOADED---")
	PbUtils.fade_out_node(start)
	animation_player.play_backwards("Drop")
	await animation_player.animation_finished
	
	#var payload : Dictionary = {"game_id": "test2"}
	#
	#var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("add_game_to_search", JSON.stringify(payload))
	#if response.is_exception():
		#push_warning("Error: %s" % response.exception.message)
	#
	#print("Connected!")
	
	search.pressed.connect(search_games)
	search_bar.text_submitted.connect(search_bar_submitted)
	
	#get_all_games()

func featured_game_pressed(game_id: String) -> void:
	var game_author : String = ""
	var games: Dictionary = await get_all_games()
	var game_info : GameInfo
	for g in games:
		if g == game_id:
			game_author = games.get(g)
			if game_author == null:
				return
			game_info = await get_game_info(g, game_author)
			break
	
	start_game(game_info.file_name, game_info.game_name, game_info.game_author, game_info.game_id)

func search_bar_submitted(_text: String) -> void:
	search_games()

func search_games() -> void:
	%LoadingSearch.show()
	var search_term : String = search_bar.text
	
	var all_games : Dictionary = await get_all_games()
	
	var games : Array = PbUtils.find_closest_strings(search_term, all_games, 10)
	
	for g in games:
		var game_creator : String = all_games.get(g)
		print("Game: %s, by: %s" % [g, game_creator])
		
		var game_info : GameInfo = await get_game_info(g, game_creator)
		
		var game_button: WebTextureButton = await WebTextureButton.new(game_info.game_image_rect_url, true, game_info.game_name, Vector2(190, 256))
		game_button.name = g
		
		%SearchGames.add_child(game_button)
		game_button.pressed.connect(start_game.bind(game_info.file_name, game_info.game_name, game_info.game_author, game_info.game_id))
	
	%LoadingSearch.hide()

func start_game(game_file_name: String, game_name: String, game_download_user: String, game_id: String) -> void:
	print("File name: %s, game name: %s" % [game_file_name, game_name])
	var load_game : LoadGame = LOAD_GAME_SCENE.instantiate()
	load_game.game_id = game_id
	load_game.game_download_file = game_file_name
	load_game.game_download_user = game_download_user
	load_game.game_name = game_name
	get_viewport().add_child(load_game)

class GameInfo:
	var game_image_square_url: String
	var game_image_rect_url: String
	
	var game_name: String
	var game_author: String
	var game_id: String
	
	var is_error : bool = false
	var error: String
	
	var file_name : String
	func _init(
		u_game_image_square_url: String = "",
		u_game_image_rect_url: String = "",
		u_game_name: String = "",
		u_game_author: String = "",
		u_game_id: String = "",
		u_file_name: String = "",
		u_error: String = "",
		u_is_error : bool = false
	) -> void:
		game_image_square_url = u_game_image_square_url
		game_image_rect_url = u_game_image_rect_url
		game_name = u_game_name
		game_author = u_game_author
		game_id = u_game_id
		file_name = u_file_name
		is_error = u_is_error
		error = u_error

func get_game_info(game_id: String, game_author: String) -> GameInfo:
	var user_result : NakamaAPI.ApiUsers = await NakamaManager.nakama_client.get_users_async(NakamaManager.nakama_session, [], [game_author])
	if user_result.is_exception():
		push_error("Something wen wrong getting users! Error: %s" % user_result.exception.message)
		return GameInfo.new("", "", "", "", "", "", user_result.exception.message, true)
	
	var author_id : String = user_result.users[0].id
	
	var read_object_id : NakamaStorageObjectId = NakamaStorageObjectId.new("Dev_Games_%s" % game_author, "games", author_id)
	
	var result : NakamaAPI.ApiStorageObjects = await NakamaManager.nakama_client.read_storage_objects_async(NakamaManager.nakama_session, [read_object_id])
	
	if result.is_exception():
		push_error("Failed retriving games! Error: %s" % result.exception.message)
	
	#print("\nGame: %s\n" % result.objects.get(0).value)
	
	var value : Dictionary = JSON.parse_string(result.objects.get(0).value)
	
	if value == null:
		return GameInfo.new("", "", "", "", "", "", "value not found! Does this user exist? Is their game public? Are you being a sneeky hacker!?! AHHHH", true)
	
	if not value.has(game_id):
		return GameInfo.new("", "", "", "", "", "", "Game ID not found!", true)
	
	var game : Dictionary = value.get(game_id)
	print("\nGame info: %s\n" % game)
	
	var _game_image_square_url: String = game.get("icon_square")
	var _game_image_rect_url: String = game.get("icon_long")
	
	var _game_name: String = game.get("game_name")
	var _game_author: String = game_author
	var _game_id: String = game_id
	var _file_name : String = game.get("file_name")
	
	return GameInfo.new(
		_game_image_square_url,
		_game_image_rect_url,
		_game_name,
		_game_author,
		_game_id,
		_file_name,
	)

func get_all_games() -> Dictionary:
	var read_object_id : NakamaStorageObjectId = NakamaStorageObjectId.new("game_info", "games", NakamaManager.server_id)
	
	var result : NakamaAPI.ApiStorageObjects = await NakamaManager.nakama_client.read_storage_objects_async(NakamaManager.nakama_session, [read_object_id])
	
	print("\n%s\n" % result)
	
	
	return JSON.parse_string(result.objects[0].value)

#var read_object_id = NakamaStorageObjectId.new("unlocks", "hats", session.user_id)
#
#var result : NakamaAPI.ApiStorageObjects = await client.read_storage_objects_async(session, read_object_id)
#
#print("Unlocked hats: ")
#for o in result.objects:
	#print("%s" % o)


func pop_up() -> void:
	animation_player.play_backwards("Drop")

func _on_settings_pressed() -> void:
	var settings : Control = SETTINGS_SCENE.instantiate()
	animation_player.play("Drop")
	await animation_player.animation_finished
	get_viewport().add_child(settings)
	settings.close.connect(pop_up)
