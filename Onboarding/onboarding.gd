extends Control

class_name Onboarding

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var lets_go: Button = $PanelContainer/MarginContainer/Control/ProfilePicture/VBoxContainer/LetsGo
@onready var line_edit: LineEdit = $PanelContainer/MarginContainer/Control/ProfilePicture/VBoxContainer/LineEdit
#@onready var line_edit_2: LineEdit = $PanelContainer/MarginContainer/Control/ProfilePicture/VBoxContainer/LineEdit2
@onready var username_le: LineEdit = $PanelContainer/MarginContainer/Control/ProfilePicture/VBoxContainer/UsernameLE
@onready var error: Label = $PanelContainer/MarginContainer/Control/Error

var submitting : bool = false
var showing : bool = false

func onboard() -> Error:
	if !showing:
		animation_player.play_backwards("Drop")
		showing = true
	
	await lets_go.pressed
	
	lets_go.disabled = true
	line_edit.editable = false
	username_le.editable = false
	submitting = true
	var dicebear_url : String = "https://api.dicebear.powerblock.hackclub.app/10.x/miniavs/svg?blushProbability=50&bodyProbability=100&eyesProbability=100&mouthVariant=default&mustacheProbability=50&borderRadius=20&backgroundColor=813d9c,b6e3f4,8ff0a4&backgroundColorAngle=-118&backgroundColorFillStops=2&seed=%s" % username_le.text
	var account_update_result : NakamaAsyncResult = await NakamaManager.nakama_client.update_account_async(NakamaManager.nakama_session, username_le.text, line_edit.text, dicebear_url)
	if account_update_result.is_exception():
		var error_l : String = account_update_result.exception.message.lstrip("Error: ")
		var error_dict : Dictionary = JSON.parse_string(error_l.rstrip(" at Error (native)"))
		#print("\n%s\n" % error_dict.get("message"))
		
		push_error("Something went wrong updating the account: %s" % error_dict.get("message"))
		
		error.text = error_dict.get("message")
		lets_go.disabled = !true
		line_edit.editable = !false
		username_le.editable = !false
		submitting = !true
		return await onboard()
	
	animation_player.play("Drop")
	
	await animation_player.animation_finished
	queue_free()
	return OK
