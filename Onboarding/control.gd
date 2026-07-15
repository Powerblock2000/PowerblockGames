extends Control

@onready var profile_picture: TextureRect = $ProfilePicture
@onready var lets_go: Button = $ProfilePicture/VBoxContainer/LetsGo
@onready var username: UsernameDisplay = $Username
@onready var line_edit: LineEdit = $ProfilePicture/VBoxContainer/LineEdit
#@onready var line_edit_2: LineEdit = $ProfilePicture/VBoxContainer/LineEdit2
@onready var username_le: LineEdit = $ProfilePicture/VBoxContainer/UsernameLE
@onready var onboarding: Onboarding = $"../../.."

func _ready() -> void:
	var user : NakamaAPI.ApiUser = await NakamaManager.get_nakama_user()
	var dicebear_url : String = "https://api.dicebear.powerblock.hackclub.app/10.x/miniavs/svg?blushProbability=50&bodyProbability=100&eyesProbability=100&mouthVariant=default&mustacheProbability=50&borderRadius=20&backgroundColor=813d9c,b6e3f4,8ff0a4&backgroundColorAngle=-118&backgroundColorFillStops=2&seed=%s" % user.username
	
	var metadata : Dictionary = JSON.parse_string(user.metadata)
	
	if metadata.has("provider"):
		if metadata.get("provider") == "hackclub" and metadata.get("verified") == "verified":
			username.hackclub_login = true
	
	username.username = user.username
	username_le.text = user.username
	
	profile_picture.texture = await PbUtils.get_image_from_url(dicebear_url, 4)
	($ProfilePicture/ColorRect as ColorRect).hide()
	
	await NakamaManager.nakama_client.update_account_async(NakamaManager.nakama_session, null, null, dicebear_url)

func _process(_delta: float) -> void:
	var new_text : String = line_edit.text
	var new_username : String = username_le.text
	if new_text != "" and not onboarding.submitting:
		lets_go.disabled = false
		lets_go.text = "Looks Good!"
	elif new_text != "" and new_username != "" and not onboarding.submitting:
		lets_go.disabled = false
		lets_go.text = "Lets mix it up!"
	else:
		lets_go.disabled = true
