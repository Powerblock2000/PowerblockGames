extends CanvasLayer

@onready var animation_player: AnimationPlayer = $GameManagement/AnimationPlayer

var in_game : bool = false

func _input(_event: InputEvent) -> void:
	if not in_game: return
	if Input.is_key_label_pressed(KEY_ESCAPE):
		animation_player.play("FlyIn")

func resume() -> void:
	animation_player.play_backwards("FlyIn")

func quit() -> void:
	in_game = false
	var scene: PackedScene = await PbUtils.load_resource_in_bg("res://MainMenu/main_menu.tscn")
	resume()
	get_tree().change_scene_to_packed(scene)

func _on_button_2_pressed() -> void:
	resume()

func _on_button_pressed() -> void:
	quit()
