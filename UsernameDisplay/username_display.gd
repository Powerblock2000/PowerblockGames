@tool
class_name UsernameDisplay

extends RichTextLabel

@export var font_size : int = 16

var hackclub_login : bool = false
var developer : bool = false
var username : String = "SampleUser":
	set(value):
		username = value
		update_user_icons()

func _ready() -> void:
	bbcode_enabled = true
	fit_content = true
	hint_underlined = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	
	update_user_icons()

func update_user_icons() -> void:
	if not Engine.is_editor_hint() and not username == "SampleUser":
		var result : NakamaAPI.ApiUsers = await NakamaManager.nakama_client.get_users_async(NakamaManager.nakama_session, [], [username])
		
		if result.is_exception():
			return
		
		if result.users.is_empty():
			return
		
		var user = result.users[0]
		
		var metadata : Dictionary = JSON.parse_string(user.metadata)
		
		if metadata.has("provider") and metadata.get("provider") == "hackclub" and metadata.has("verified") and metadata.get("verified") == "verified":
			hackclub_login = true
		if metadata.has("developer") and metadata.get("developer") == true:
			developer = true

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		bbcode_enabled = true
		fit_content = true
		hint_underlined = false
	
	add_theme_font_size_override("normal_font_size", font_size)
	var text_args : String = ""
	if hackclub_login:
		text_args = "[hint=Logged in with Hackclub][img=0x%s]res://icon-rounded.png[/img][/hint]" % str(font_size)
	if developer:
		text_args += " [hint=Developer][img=0x%s]res://Developer.png[/img][/hint]" % str(font_size)
	text = "%s %s" % [username, text_args]
