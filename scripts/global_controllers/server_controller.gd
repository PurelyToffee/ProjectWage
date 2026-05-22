extends Node

const TOKEN_PATH = "user://itch_token.dat"
const SERVER_DOMAIN = "http://localhost:5173"

#region treat token

func save_token(token: String):
	var file = FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
	file.store_string(token)
	file.close()

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
	OS.shell_open("https://yourdomain.com/auth/login")
		
func on_login_success(token: String):
	save_token(token)

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
	# Try app launcher token first
	var token = OS.get_environment("ITCHIO_API_KEY")

	# Fall back to saved token
	if token == "":
		token = load_token()

	if token == "":
		# No token at all, prompt login
		show_login_prompt()
		return

	# Validate the token with your server
	var response = await post_to_server("/api/user", token)
	if response.response_code == 401:
		# Token expired, delete it and prompt login
		DirAccess.remove_absolute(TOKEN_PATH)
		show_login_prompt()
	else:
		# Good to go, player is logged in silently
		print("Logged in!")
		
