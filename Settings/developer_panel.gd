extends VBoxContainer

@onready var dev_panel: Button = $"Dev Panel"
@onready var label: Label = $Label
@onready var apply: Button = $Apply
@onready var loading: Control = $Loading
@onready var apply_ce: CodeEdit = $ApplyCE

func _ready() -> void:
	visibility_changed.connect(selection_changed)

func selection_changed() -> void:
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	var metadata : Dictionary = JSON.parse_string(user.metadata)
	
	if metadata.has("developer") and metadata["developer"]:
		dev_panel.disabled = false
		apply_ce.hide()
		apply.hide()
		label.hide()
	else:
		print("Not developer :(")
		dev_panel.hide()
		apply.disabled = false
	
	loading.hide()

	#var payload : Dictionary = {"game_id": "test2"}
	#
	#var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("add_game_to_search", JSON.stringify(payload))
	#if response.is_exception():
		#push_warning("Error: %s" % response.exception.message)
	#
	#print("Connected!")

func _on_dev_panel_pressed() -> void:
	OS.shell_open("https://github.com/Powerblock2000/PowerblockGamesDevTools/releases")

func _on_apply_pressed() -> void:
	var payload : Dictionary = {"apply_reason": apply_ce.text}
	var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("apply_for_dev", JSON.stringify(payload))
	if response.is_exception():
		push_warning("Error: %s" % response.exception.message)
	
	print("Connected!")
