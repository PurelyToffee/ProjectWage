extends Node

const TOKEN_PATH = "user://itch_token.dat"
const SERVER_DOMAIN = "http://wage.toffees.place"

const REDIRECT_PORT = 7878
var server := TCPServer.new()

#region treat token

func save_token(token: String):
	
	var file = FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
	file.store_string(token)
	file.close()
	print("Token saved to: ", TOKEN_PATH)

func load_token() -> String:
	if not FileAccess.file_exists(TOKEN_PATH):
		return ""
	var file = FileAccess.open(TOKEN_PATH, FileAccess.READ)
	var token = file.get_as_text()
	file.close()
	return token

#endregion

#region login

func show_login_prompt():
	var err = server.listen(REDIRECT_PORT)
	print("Server listen error code: ", err)  # 0 = OK
	OS.shell_open("%s/auth/login?redirect=game" % SERVER_DOMAIN)
		
func on_login_success(token: String):
	save_token(token)
	print("Token saved: ", token)


#endregion

func post_to_server(endpoint: String, token: String, body: Dictionary = {}) -> HTTPRequest:
	var http = HTTPRequest.new()
	add_child(http)

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]

	http.request(
		SERVER_DOMAIN + endpoint,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(body)
	)

	return http

func _ready():
	var token = OS.get_environment("ITCHIO_API_KEY")
	if token == "":
		token = load_token()
	if token == "":
		show_login_prompt()
		return
	
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_user_validated)
	http.request(
		SERVER_DOMAIN + "/api/user",
		["Content-Type: application/json", "Authorization: Bearer " + token],
		HTTPClient.METHOD_POST
	)

func _on_user_validated(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == 401:
		DirAccess.remove_absolute(TOKEN_PATH)
		show_login_prompt()
	else:
		var data = JSON.parse_string(body.get_string_from_utf8())
		print(data)
		print("Logged in as: ", data.user.username)

func send_performance(levelName: String, time_ms: int, score: int) -> void:
	
	var token = load_token()
	if token == "":
		print("No token, can't send performance")
		return

	var http = post_to_server("/api/submit", token, {
		"levelName": levelName,
		"timeMs": time_ms,
		"score": score
	})

	http.request_completed.connect(func(result, response_code, headers, body):
		if response_code == 200 or response_code == 201:
			print("Performance submitted successfully")
		else:
			print("Failed to submit performance: ", response_code)
			print(body.get_string_from_utf8())
		http.queue_free()
	)


func _process(delta):
	if not server.is_listening():
		return
		
	if server.is_connection_available():
		print("Connection received!")
		var conn = server.take_connection()
		
		var timeout = 0.0
		while conn.get_available_bytes() == 0 and timeout < 3.0:
			await get_tree().process_frame
			timeout += delta
		
		var request = conn.get_string(conn.get_available_bytes())
		print("Raw request: ", request)
		
		# Send a nice response so the browser doesn't show an error
		var response = "HTTP/1.1 302 Found\r\nLocation: %s/auth/success\r\n\r\n" % SERVER_DOMAIN
		conn.put_data(response.to_utf8_buffer())
		
		# Parse the token
		var regex = RegEx.new()
		regex.compile("access_token=([^& \\n\\r]+)")
		var result = regex.search(request)
		if result:
			var token = result.get_string(1)
			print("Token found: ", token)
			save_token(token)
			server.stop()
			on_login_success(token)
		else:
			print("No token found in request")
