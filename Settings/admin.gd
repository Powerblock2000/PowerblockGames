extends VBoxContainer
@onready var dev_username: LineEdit = $HBoxContainer/DevUsername
@onready var admin_panel: Button = $"../../VBoxContainer/AdminPanel"

func _ready() -> void:
	admin_panel.hide()
	
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	var metadata : Dictionary = JSON.parse_string(user.metadata)
	
	if metadata.has("admin") and metadata.get("admin") == true:
		admin_panel.show()

func _on_approve_user_pressed() -> void:
	var payload : Dictionary = {"username": dev_username.text}
	var response : NakamaAPI.ApiRpc = await NakamaManager.nakama_socket.rpc_async("give_user_dev", JSON.stringify(payload))
	if response.is_exception():
		push_warning("Error: %s" % response.exception.message)
	
	dev_username.editable = false
	dev_username.text = "User has been approved!"
	await get_tree().create_timer(2).timeout
	dev_username.editable = true
	dev_username.text = ""
