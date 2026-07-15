extends Node

signal _resource_loaded

var resource : Variant
var resource_path : String
var loading_resource : bool = false

func find_closest_strings(search_term: String, dict: Dictionary, top_n: int = 1) -> Array:
	var keys = dict.keys()
	
	keys.sort_custom(func(a, b): 
		return search_term.similarity(a) > search_term.similarity(b)
	)
	
	return keys.slice(0, top_n)

func random_string(length: int, chars: String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_-+={}[]|:;"<>,./?') -> String:
	var string : String = ""
	var char_len : int = chars.length()
	
	for i in length:
		string += chars[randi() % char_len]
	
	return string

func load_resource_in_bg(path: String) -> Variant:
	if loading_resource: return
	loading_resource = true
	resource_path = path
	ResourceLoader.load_threaded_request(path)
	await _resource_loaded
	loading_resource = false
	return resource

func _process(_delta: float) -> void:
	check_for_resource_load()

func check_for_resource_load() -> void:
	if ResourceLoader.load_threaded_get_status(resource_path) == 3:
		resource = ResourceLoader.load_threaded_get(resource_path)
		_resource_loaded.emit()
	elif ResourceLoader.load_threaded_get_status(resource_path) == 2 or ResourceLoader.load_threaded_get_status(resource_path) == 0:
		resource = "Failed loading resource!"
		_resource_loaded.emit()

func get_download_url(file_name: String, get_as_error: bool = false) -> Variant:
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	
	var headers = [
	"Authorization: Bearer " + NakamaManager.nakama_session.token
	]
	
	http.request("http://0.0.0.0:8000/get-download-url?filename=%s" % file_name.uri_encode(), headers)
	
	var response : Array = await http.request_completed
	http.queue_free()
	
	var body : PackedByteArray = response[3]
	
	var response_code : int = response[1]
	
	if response_code != 200:
		push_error("failed: %s" % response_code)
		print(body.get_string_from_utf8())
		if get_as_error:
			return {"Error": body.get_string_from_utf8()}
		return "Error: %s" % body.get_string_from_utf8()
	
	var json : Dictionary = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		push_error("Failed")
		if get_as_error:
			return {"Error": "Failed Parsing JSON"}
		return "Error: Failed parsing JSON"
	
	var url : String = json["url"]
	return url

func fade_out_node(node: Control, time : float = .3) -> void:
	var tween : Tween = create_tween()
	
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 0.0), time)
	await tween.finished
	tween.kill()
	node.hide()

func fade_in_node(node: Control, time : float = .3) -> void:
	node.show()
	node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween : Tween = create_tween()
	
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), time)
	await tween.finished
	tween.kill()

func get_image_from_url(url: String, scale : float = 1) -> Texture2D:
	var http_request : HTTPRequest = HTTPRequest.new()
	add_child(http_request)
	
	var error : Error = http_request.request(url)
	if error != OK:
		print("Error getting image: %s, URL: %s" % [error_string(error), url])
		return PlaceholderTexture2D.new()
	var request_return = await http_request.request_completed
	http_request.queue_free()
	var result = request_return[0]
	var body = request_return[3]
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Error getting image: %s, url: %s" % [result, url])
		return PlaceholderTexture2D.new()
	
	var image : Image = Image.new()
	
	var error_iamge = image.load_svg_from_buffer(body, scale)
	if error_iamge != OK:
		push_error("Error getting image: %s, URL: %s" % [error_string(error_iamge), url])
		return PlaceholderTexture2D.new()
	
	return ImageTexture.create_from_image(image)

func get_file_from_s3(filename: String) -> Dictionary:
	var headers = [
		"Authorization: Bearer " + NakamaManager.nakama_session.token
	]
	
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	
	http.request("http://0.0.0.0:8000/get-download-url?filename=%s" % filename, headers)
	
	var response : Array = await http.request_completed
	
	http.queue_free()
	
	var body : PackedByteArray = response[3]
	
	if response[1] != 200:
		push_error("failed: %s" % response[1])
		push_error(body.get_string_from_utf8())
		return {"error_type": "http", "error": body.get_string_from_utf8()}
	
	var json : Dictionary = JSON.parse_string(body.get_string_from_utf8())
	
	if json == null:
		push_error("Failed parsing JSON")
		return {"error_type": "json", "error": "Falied parsing json"}
	
	var url : String = json["url"]
	print("\n%s\n%s\n" % [filename, url])
	
	var file : Dictionary = await get_file_from_url(url)
	
	if file.has("Error"):
		push_error(file)
		return file
	
	return file

func get_file_from_url(url: String) -> Dictionary:
	var http : HTTPRequest = HTTPRequest.new()
	add_child(http)
	http.request(url)
	
	var response : Array = await http.request_completed
	http.queue_free()
	
	if response[1] != 200:
		return {"Error": (response[3] as PackedByteArray).get_string_from_utf8()}
	
	return {"file" : (response[3] as PackedByteArray)}
