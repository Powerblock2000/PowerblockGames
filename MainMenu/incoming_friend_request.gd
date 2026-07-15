extends Panel

class_name FriendListItemIncoming

signal friend_status_updated(friend_username : String, is_friend: bool)
signal loaded

var username : String:
	set(value):
		username = value
		name = username
		username_label.username = value

var url : String: 
	set(value):
		url = value
		profile_picture.texture = await PbUtils.get_image_from_url(url, 2)
		hide_temp_profile()
		loaded.emit()

@onready var profile_picture: TextureRect = $ProfilePicture
@onready var username_label: UsernameDisplay = $ProfilePicture/Username

func hide_temp_profile() -> void:
	($ProfilePicture/Loading as ColorRect).hide()

func _on_accept_pressed() -> void:
	friend_status_updated.emit(name, true)

func _on_decline_pressed() -> void:
	friend_status_updated.emit(name, false)
