extends Control

signal login_complete(email: String, username: String, password: String)

@onready var email_login: LineEdit = $MarginContainer/VBoxContainer/EmailLogin
@onready var password_login: LineEdit = $MarginContainer/VBoxContainer/PasswordLogin
@onready var control: Control = $MarginContainer/VBoxContainer/Control
@onready var login: Button = $MarginContainer/VBoxContainer/Login
@onready var error_login: Label = $MarginContainer/VBoxContainer/ErrorLogin

var email : String
var password : String

func error(error_text: String) -> void:
	error_login.text = error_text
	error_login.show()

func _ready() -> void:
	email_login.text_changed.connect(email_changed)
	password_login.text_changed.connect(password_changed)
	login.pressed.connect(complete_login)

func complete_login() -> void:
	login_complete.emit(email, password)

func _process(_delta: float) -> void:
	#print("Email: %s, Username: %s, Password: %s" % [email, username, password])
	
	if email != "" and password != "":
		login.disabled = false

func email_changed(new_email: String) -> void:
	if new_email == "":
		login.disabled = true
	email = new_email
	#print(email)

func password_changed(new_password: String) -> void:
	if new_password == "":
		login.disabled = true
	password = new_password
