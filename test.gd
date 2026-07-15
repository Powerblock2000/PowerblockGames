extends Node

func _ready() -> void:
	NakamaManager.connect_to_nakama(PowerblockAuth.AuthMethods.DEVICE_ID, false)
