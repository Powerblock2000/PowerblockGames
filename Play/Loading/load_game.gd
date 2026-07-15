extends Control

class_name LoadGame

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var confetti: CPUParticles2D = $PanelContainer/CPUParticles2D
@onready var fun_mouse: GPUParticles2D = $GPUParticles2D
@onready var mouse_confetti: CPUParticles2D = $CPUParticles2D
@onready var label: Label = %Label

var fun_mode : bool = false
var game_download_user : String:
	set(value):
		game_download_user = value
		print(value)
var game_download_file : String
var game_name : String:
	set(value):
		game_name = value
var game_id : String

func _process(_delta: float) -> void:
	if game_name != "":
		label.text = game_name
	
	fun_mouse.position = get_viewport().get_mouse_position()
	
	fun_mouse.emitting = fun_mode

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and fun_mode:
		mouse_confetti.position = get_viewport().get_mouse_position()
		mouse_confetti.emitting = true

func _ready() -> void:
	await get_tree().create_timer(.5).timeout
	animation_player.play("Loadin")
	await animation_player.animation_finished
	
	animation_player.play("Loading")
	
	var file_bytes : Dictionary = await PbUtils.get_file_from_s3("%s/%s" % [game_download_user, game_download_file])
	print()
	if file_bytes.has("error"):
		push_error("Failed downloading game: %s" % file_bytes.get("error"))
	
	if not DirAccess.dir_exists_absolute("user://games"):
		var dir_error : Error = DirAccess.make_dir_recursive_absolute("user://games")
		if dir_error != OK:
			push_warning("failed creating directory!")
			return
	
	var file : FileAccess = FileAccess.open("user://games/%s.%s.%s" % [game_download_user, game_download_file.left(game_download_file.length() - 4), game_download_file.right(3)], FileAccess.WRITE_READ)
	if file:
		file.store_buffer(file_bytes.get("file"))
		file.close()
	else:
		push_error("Error saving file!")
		return
	
	# var success = ProjectSettings.load_resource_pack
	
	print("user://games/%s.%s.%s" % [game_download_user, game_download_file.left(game_download_file.length() - 4), game_download_file.right(3)])
	
	var success = ProjectSettings.load_resource_pack("user://games/%s.%s.%s" % [game_download_user, game_download_file.left(game_download_file.length() - 4), game_download_file.right(3)], false)
	if not success:
		push_error("Failed loading PCK! Uh-oh")
		return
	print("Loaded PCK. Get ready to play!!!")
	
	var error = await PbUtils.load_resource_in_bg("res://%s/main.tscn" % game_id)
	
	if error is String:
		push_error("Error loading pck into game!")
		return
	
	get_tree().change_scene_to_packed(error)
	GameManagement.in_game = true
	queue_free()

func _on_check_button_toggled(toggled_on: bool) -> void:
	fun_mode = toggled_on
	if !toggled_on: return
	
	confetti.emitting = true
