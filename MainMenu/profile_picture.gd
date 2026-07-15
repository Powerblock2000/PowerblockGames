extends WebTextureButton

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var username: UsernameDisplay = $PanelContainer/Control/Username
@onready var control: Control = $PanelContainer/Control

var menu_down : bool = false

func _on_main_menu_connected() -> void:
	pressed.connect(drop_down)
	await get_tree().create_timer(.5).timeout
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	
	var developer : bool = false
	var hackclub_login : bool = false
	
	var metadata : Dictionary = JSON.parse_string(user.metadata)
	if metadata.has("provider") and metadata.get("provider") == "hackclub" and metadata.get("verified") == "verified":
		hackclub_login = true
	if metadata.has("developer") and metadata.get("developer"):
		developer = true
	
	username.username = user.username
	username.hackclub_login = hackclub_login
	username.developer = developer
	texture_normal = await PbUtils.get_image_from_url(await NakamaManager.get_avatar_url(), 4)

func drop_down() -> void:
	control.set_sizes()
	await get_tree().process_frame
	if menu_down:
		animation_player.play_backwards("OpenPanel")
	else:
		animation_player.play("OpenPanel")
	tween_enabled = !tween_enabled
	menu_down = !menu_down
