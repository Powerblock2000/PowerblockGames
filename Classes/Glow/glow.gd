extends TextureRect

class_name GlowRect

@export var time : float = .5

func fade_in() -> void:
	modulate.a = 0
	show()
	var tween : Tween = create_tween()
	
	tween.tween_property(self, "modulate", Color(modulate.r, modulate.g, modulate.b, 1), time)

func fade_out() -> void:
	var tween : Tween = create_tween()
	
	tween.tween_property(self, "modulate", Color(modulate.r, modulate.g, modulate.b, 0), time)
	await tween.finished
	hide()
