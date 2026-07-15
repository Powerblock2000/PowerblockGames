extends Window

class_name AuthEmail

signal complete_login(email : String, password: String, username : String, create_account : bool)

@onready var login: Control = $TabContainer/Login
@onready var signup: Control = $TabContainer/Signup
@onready var loading: ColorRect = $Loading
@onready var color_rect: ColorRect = $ColorRect
@onready var company_logo: TextureRect = $CompanyLogo
@onready var animation_player: AnimationPlayer = $Loading/AnimationPlayer

var logo : Texture2D
var color : Color

func fade_in(node: Control, time : float = .3) -> void:
	node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	node.show()
	
	var tween : Tween = create_tween()
	
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), time)
	await tween.finished
	return

func fade_out(node: Control, time : float = .3) -> void:
	var tween : Tween = create_tween()
	
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 0.0), time)
	await tween.finished
	node.hide()
	return

func error(error_text: String) -> void:
	fade_out(loading)
	print(error_text)
	login.error(str(error_text))
	signup.error(str(error_text))

func _ready() -> void:
	loading.hide()
	login.login_complete.connect(login_complete)
	signup.signup_complete.connect(signup_complete)
	check_logo.call_deferred()

func check_logo() -> void:
	if logo:
		company_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		company_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		company_logo.texture = logo
	if color:
		color_rect.color = color

func login_complete(email: String, password: String) -> void:
	fade_in(loading)
	animation_player.play("Loading")
	await get_tree().create_timer(3).timeout
	complete_login.emit(email, password, "", false)

func signup_complete(email: String, username: String, password: String) -> void:
	fade_in(loading)
	animation_player.play("Loading")
	await get_tree().create_timer(3).timeout
	complete_login.emit(email, password, username, true)

func _on_close_requested() -> void:
	complete_login.emit(null, null, null, null)
	queue_free()
