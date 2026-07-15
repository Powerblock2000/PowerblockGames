extends TextureButton

class_name WebTextureButton

var time : float = .082
var tween_enabled : bool = true

func _init(image_url: String = "", ignore_image: bool = false, tooltip: String = "", _custom_minimum_size : Vector2 = Vector2(0,0)) -> void:
	if image_url != "":
		var texture : Texture2D = await PbUtils.get_image_from_url(image_url, 4)
		
		texture_normal = texture
	if ignore_image:
		ignore_texture_size = true
		stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	if _custom_minimum_size != Vector2.ZERO:
		custom_minimum_size = _custom_minimum_size
	
	tooltip_text = tooltip

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	if get_parent() is Container:
		offset_transform_enabled = true
	mouse_entered.connect(mouse_entered_)
	mouse_exited.connect(mouse_exited_)
	button_down.connect(button_down_)
	button_up.connect(button_up_)

func mouse_entered_() -> void:
	if !tween_enabled: return
	z_index += 1
	
	var tween : Tween = create_tween()
	if get_parent() is Container:
		tween.tween_property(self, "offset_transform_scale", Vector2(1.1,1.1), time)
	else:
		tween.tween_property(self, "scale", Vector2(1.1,1.1), time)

func mouse_exited_() -> void:
	z_index = 0
	var tween : Tween = create_tween()
	if get_parent() is Container:
		tween.tween_property(self, "offset_transform_scale", Vector2(1,1), time)
	else:
		tween.tween_property(self, "scale", Vector2(1,1), time)

func button_down_() -> void:
	if !tween_enabled: return
	var tween : Tween = create_tween()
	if get_parent() is Container:
		tween.tween_property(self, "offset_transform_scale", Vector2(.9,.9), time)
	else:
		tween.tween_property(self, "scale", Vector2(.9,.9), time)

func button_up_() -> void:
	if !tween_enabled: return
	var tween : Tween = create_tween()
	if get_parent() is Container:
		tween.tween_property(self, "offset_transform_scale", Vector2(1.1,1.1), time)
	else:
		tween.tween_property(self, "scale", Vector2(1.1,1.1), time)
