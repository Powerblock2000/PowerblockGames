extends Control

signal close

@onready var v_box_container: VBoxContainer = $PanelContainer/MarginContainer/ScrollContainer/HBoxContainer/VBoxContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var active_page : String :
	set(value):
		var current_page = get_node("PanelContainer/MarginContainer/ScrollContainer/HBoxContainer/Pages/%s" % value)
		if current_page == null: return
		current_page.show()
		if active_page != "":
			get_node("PanelContainer/MarginContainer/ScrollContainer/HBoxContainer/Pages/%s" % active_page).hide()
		active_page = value

#$PanelContainer/MarginContainer/ScrollContainer/HBoxContainer/Pages

func _ready() -> void:
	animation_player.play_backwards("Drop")
	
	active_page = "Privacy"
	for child in v_box_container.get_children():
		if child is Button:
			(child as Button).pressed.connect(page_changed.bind(child))

func page_changed(button: Button) -> void:
	active_page = button.name

func _on_close_pressed() -> void:
	animation_player.play("Drop")
	await animation_player.animation_finished
	close.emit()
	queue_free()
