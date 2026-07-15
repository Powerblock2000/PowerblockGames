extends Label

class_name SlideInText

@export var time_to_complete : float = .4
@export var play_on_show : bool = false
@export var call_func_on_play : bool = false
@export var func_to_call_on_play : String
@export_node_path("Control") var node_to_call_on_play : NodePath

@onready var slide: ColorRect = $Slide

var started_playing : bool = false

func _process(_delta: float) -> void:
	if visible and not started_playing and play_on_show:
		print("Playing!")
		play.call_deferred()

func play() -> void:
	await get_tree().process_frame
	
	if not node_to_call_on_play.is_empty():
		get_node(node_to_call_on_play).call(func_to_call_on_play)
	
	started_playing = true
	var tween : Tween = create_tween()
	print("Text: %s, Length: %s" % [text, text.length()])
	tween.tween_property(self, "visible_characters", text.length(), time_to_complete)
	tween.parallel().tween_property(slide, "position", Vector2(size.x + 5, slide.position.y),  time_to_complete)
