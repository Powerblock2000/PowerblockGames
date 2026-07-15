extends MarginContainer

class_name DevPanelGame

signal updated_game(_game_id: String, updated_game_name: String, update_game_icon_long_url: String, update_game_icon_square_url: String, update_pck_path: String)

@onready var game_name_le: LineEdit = %VBoxContainer/GameName
@onready var game_id_le: Label = %VBoxContainer/GameID

@onready var game_icon_square: WebTextureButton = $GridContainer/GameIconSquare
@onready var game_icon_wide: WebTextureButton = $GridContainer/GameIconWide

var updated_game_id : bool = false:
	set(_value):
		updated_game_id = true

var game_icon_long_url : String:
	set(value):
		game_icon_long_url = value
		game_icon_wide.texture_normal = await PbUtils.get_image_from_url(game_icon_long_url, 4)

var game_icon_square_url : String:
	set(value):
		game_icon_square_url = value
		game_icon_square.texture_normal = await PbUtils.get_image_from_url(game_icon_square_url, 8)

var game_name : String:
	set(value):
		game_name = value
		game_name_le.text = value

var game_id : String:
	set(value):
		if not updated_game_id:
			updated_game_id = true
			game_id = value
			name = game_id
			game_id_le.text = "ID: %s" % game_id

func _on_save_pressed() -> void:
	print(game_name_le.text)
	updated_game.emit(name, game_name_le.text, game_icon_long_url, game_icon_square_url, "")
