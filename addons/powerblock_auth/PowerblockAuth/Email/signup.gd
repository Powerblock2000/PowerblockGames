extends Control

signal signup_complete(email: String, username: String, password: String)

@onready var email_signup: LineEdit = $MarginContainer/VBoxContainer/EmailSignup
@onready var username_signup: LineEdit = $MarginContainer/VBoxContainer/UsernameSignup
@onready var password_signup: LineEdit = $MarginContainer/VBoxContainer/PasswordSignup
@onready var signup: Button = $MarginContainer/VBoxContainer/Signup
@onready var error_signup: Label = $MarginContainer/VBoxContainer/ErrorSignup

var email : String
var username : String
var password : String

func error(error_text: String) -> void:
	error_signup.text = error_text
	error_signup.show()

func _ready() -> void:
	email_signup.text_changed.connect(email_changed)
	username_signup.text_changed.connect(username_changed)
	password_signup.text_changed.connect(password_changed)
	signup.pressed.connect(complete_signup)

func complete_signup() -> void:
	signup_complete.emit(email, username, password)

func _process(_delta: float) -> void:
	#print("Email: %s, Username: %s, Password: %s" % [email, username, password])
	
	if email != "" and username != "" and password != "":
		signup.disabled = false

func email_changed(new_email: String) -> void:
	if new_email == "":
		signup.disabled = true
	email = new_email
	#print(email)

func username_changed(new_username: String) -> void:
	if new_username == "":
		signup.disabled = true
	username = new_username
	#print(username)

func password_changed(new_password: String) -> void:
	if new_password == "":
		signup.disabled = true
	password = new_password
