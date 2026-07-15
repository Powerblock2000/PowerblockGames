extends Control

@onready var username: UsernameDisplay = $Username

func set_sizes() -> void:
	await get_tree().process_frame
	custom_minimum_size.x = 51 + username.size.x
	
	print(custom_minimum_size)
