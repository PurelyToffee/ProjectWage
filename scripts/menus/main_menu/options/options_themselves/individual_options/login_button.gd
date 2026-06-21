extends MenuOption

@onready var label: Label = %Label
@onready var username: Label = %Username

func _process(delta: float) -> void:
	if ServerController.is_logged_in():
		username.visible = true;
		username.text = ServerController.current_username
		label.text = "Logout"
	else:
		username.visible = false;
		label.text = "Login"
