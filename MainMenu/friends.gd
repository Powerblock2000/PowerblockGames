extends MarginContainer

const INCOMING_FRIEND_REQUEST_SCENE = preload("uid://dfwqngigtisal")
const OUTGOING_FRIEND_REQUEST_SCENE = preload("uid://t2t3q1qp1wh6")
const FRIEND_LIST_ITEM_SCENE = preload("uid://cpjm0hbecxg44")

@onready var main_menu: ColorRect = $"../../../../.."

func _on_main_menu_connected() -> void:
	#await NakamaManager.nakama_client.add_friends_async(NakamaManager.nakama_session, null, ["Powerblock2000"])
	print("Adding friends")
	refresh_friends_list()

func refresh_friends_list() -> void:
	for f in (%FriendsList as VBoxContainer).get_children():
		f.queue_free()
	
	var list : NakamaAPI.ApiFriendList = await NakamaManager.nakama_client.list_friends_async(NakamaManager.nakama_session)
	if list.is_exception():
		push_error("Could not get friends: %s" % list)
		return
	
	for f in list.friends:
		var friend = (f as NakamaAPI.ApiFriend)
		if friend.state == 2:
			var incoming_friend_request : FriendListItemIncoming = INCOMING_FRIEND_REQUEST_SCENE.instantiate()
			(%FriendsList as VBoxContainer).add_child(incoming_friend_request)
			(%FriendsList as VBoxContainer).move_child(incoming_friend_request, 0)
			var clean_url : String = friend.user.avatar_url.replace("&amp;", "&")
			incoming_friend_request.url = clean_url
			incoming_friend_request.username = friend.user.username
			incoming_friend_request.friend_status_updated.connect(incoming_friend_updated)
		elif friend.state == 1:
			var outgoing_friend_request : FriendListItemRequest = OUTGOING_FRIEND_REQUEST_SCENE.instantiate()
			(%FriendsList as VBoxContainer).add_child(outgoing_friend_request)
			var clean_url : String = friend.user.avatar_url.replace("&amp;", "&")
			outgoing_friend_request.url = clean_url
			outgoing_friend_request.username = friend.user.username
			outgoing_friend_request.cancel_friend_request.connect(remove_friend)
		elif friend.state == 0:
			var friend_list_item : FriendListItem = FRIEND_LIST_ITEM_SCENE.instantiate()
			(%FriendsList as VBoxContainer).add_child(friend_list_item)
			(%FriendsList as VBoxContainer).move_child(friend_list_item, -1)
			var clean_url : String = friend.user.avatar_url.replace("&amp;", "&")
			friend_list_item.url = clean_url
			friend_list_item.username = friend.user.username
			friend_list_item.remove_friend.connect(remove_friend)
	main_menu.friends_ready = true

func add_friend(username: String) -> String:
	var error : NakamaAsyncResult = await NakamaManager.nakama_client.add_friends_async(NakamaManager.nakama_session, null, [username])
	if error.is_exception():
		push_error("Could not add friend: %s" % error.exception.message)
		return error.exception.message
	
	for f in (%FriendsList as VBoxContainer).get_children():
		if f.name == username:
			f.queue_free()
			refresh_friends_list()
			return ""
	return ""

func remove_friend(username: String) -> String:
	var error: NakamaAsyncResult = await NakamaManager.nakama_client.delete_friends_async(NakamaManager.nakama_session, [], [username])
	
	if error.is_exception():
		push_error("Could not remove friend: %s" % error.exception.message)
		return error.exception.message
	
	for f in (%FriendsList as VBoxContainer).get_children():
		if f.name == username:
			f.queue_free()
			refresh_friends_list()
			return ""
	return ""

func incoming_friend_updated(friend_username : String, is_friend: bool) -> void:
	print("%s" % friend_username)
	if is_friend:
		await add_friend(friend_username)
	else:
		await remove_friend(friend_username)

# Example output:
# state: 2, update_time: 2026-06-20T01:13:33Z, user: apple_id: <null>, avatar_url: https://api.dicebear.com/10.x/miniavs/svg?blushProbability=50&bodyProbability=100&eyesProbability=100&mouthVariant=default&mustacheProbability=50&borderRadius=20&backgroundColor=813d9c,b6e3f4,8ff0a4&backgroundColorAngle=-118&backgroundColorFillStops=2&seed=Example, create_time: 2026-06-16T17:10:24Z, display_name: Example, edge_count: <null>, facebook_id: <null>, facebook_instant_game_id: <null>, gamecenter_id: <null>, google_id: <null>, id: 29b51cc0-e302-4764-9287-d3319cd43986, lang_tag: en, location: <null>, metadata: {}, online: <null>, steam_id: <null>, timezone: <null>, update_time: 2026-06-20T01:13:33Z, username: Example, ,

func _on_refresh_pressed() -> void:
	refresh_friends_list()

func _on_add_pressed() -> void:
	var friend_username : LineEdit = (%AddFriend/FriendUsername as LineEdit)
	friend_username.editable = false
	var error : String = await add_friend(friend_username.text)
	friend_username.text = ""
	if error != "":
		friend_username.placeholder_text = error
	else:
		friend_username.placeholder_text = "Request sent!"
	await get_tree().create_timer(2).timeout
	friend_username.placeholder_text = "Add friend via username"
	friend_username.editable = true
	refresh_friends_list()
