class_name TutorialMenu extends CanvasLayer

@onready var page_count_label: Label = %PageCount
#@onready var illustration: TextureRect = %Illustration
@onready var description_label: RichTextLabel = %Description
@onready var back_button: Button = %Back
@onready var next_button: Button = %Next
@onready var done_button: Button = %Done
@onready var video_player: VideoStreamPlayer = %TutorialVideo
var video: VideoStreamTheora

var pages: Array[TutorialPageData] = []

var current_page: int = 0

#region input gate
# Parsed steps for the current page: each entry is an Array[String] of action
# names that must be pressed together. The whole sequence repeats _req_target times.
var _req_steps: Array = []
var _req_target: int = 0
var _req_step_index: int = 0
var _req_repeats_done: int = 0
var _req_armed: bool = false   # must release the combo before the next press counts
var _base_description: String = ""
#endregion


func set_pages(content : Array[TutorialPageData]) -> void:
	pages = content;

	update_page()

func on_back_pressed() -> void:
	if current_page <= 0:
		return
	current_page -= 1
	update_page()

func on_next_pressed() -> void:

	if current_page >= page_count() - 1:
		return
	# Don't let the player advance past a gated page until they've done the inputs.
	if not _gate_passed():
		return

	current_page += 1
	update_page()

func on_done_pressed() -> void:
	if not _gate_passed():
		return
	LevelController.close_tutorial()

func format_colors(text : String) -> String:
	
	text = text.replace("CRed", Color("D52224").to_html());
	text = text.replace("Highlight1", Color("FCD653FF").to_html());
	
	return text

func update_page() -> void:
	var page_count = page_count()
	page_count_label.text = "%s %d/%d" % [pages[current_page].title, current_page + 1, page_count]

	if pages.size() > current_page and pages[current_page].video != video_player.stream:
		video_player.stream = pages[current_page].video
		video_player.visible = true
		video_player.play()
		#illustration.texture = pages[current_page].image
		#illustration.visible = true
	#else:
		#illustration.texture = null
		#illustration.visible = false

	if pages.size() > current_page:
		_base_description = format_colors(pages[current_page].description);
	else:
		_base_description = ""

	_load_requirement()

	back_button.disabled = current_page == 0
	_refresh_gate()

func page_count() -> int:
	return max(pages.size(), 1)

#region input gate

# Parse the current page's required_input_steps into action lists and reset progress.
func _load_requirement() -> void:
	_req_steps = []
	_req_target = 0
	_req_step_index = 0
	_req_repeats_done = 0
	_req_armed = false

	if current_page >= pages.size():
		return

	var page := pages[current_page]
	for step_str in page.required_input_steps:
		var actions: Array[String] = []
		for raw in step_str.split("+", false):
			var action := raw.strip_edges()
			if action == "":
				continue
			if InputMap.has_action(action):
				actions.append(action)
			else:
				push_warning("TutorialMenu: unknown input action '%s' on page %d" % [action, current_page])
		if actions.size() > 0:
			_req_steps.append(actions)

	if _req_steps.size() > 0:
		_req_target = max(1, page.required_input_repeats)

func _has_requirement() -> bool:
	return _req_steps.size() > 0

# Whether the current page's input gate is satisfied (or there is no gate).
func _gate_passed() -> bool:
	return not _has_requirement() or _req_repeats_done >= _req_target

# Update advance-button states and the on-screen prompt for the current gate.
func _refresh_gate() -> void:
	var last_page := current_page >= page_count() - 1
	var gated := _has_requirement() and not _gate_passed()

	next_button.disabled = last_page or gated
	done_button.disabled = (not last_page) or gated

	description_label.text = _base_description + _gate_hint()

# A short prompt appended under the description while a gate is unmet.
func _gate_hint() -> String:
	if not _has_requirement() or _gate_passed():
		return ""

	var step: Array = _req_steps[_req_step_index]
	var combo := " + ".join(step).to_upper()

	var hint := "\n\n[ Press %s ]" % combo
	if _req_steps.size() > 1:
		hint += "  (step %d/%d)" % [_req_step_index + 1, _req_steps.size()]
	if _req_target > 1:
		hint += "  x%d/%d" % [_req_repeats_done, _req_target]
	return hint

func _process(_delta: float) -> void:
	if pages.is_empty() or not _has_requirement() or _gate_passed():
		return

	var step: Array = _req_steps[_req_step_index]

	var all_pressed := true
	for action in step:
		if not Input.is_action_pressed(action):
			all_pressed = false
			break

	if not all_pressed:
		# Combo released — ready to accept the next press.
		_req_armed = true
		return

	if not _req_armed:
		return

	# A fresh press of the current step's combo: advance.
	_req_armed = false
	_req_step_index += 1
	if _req_step_index >= _req_steps.size():
		_req_step_index = 0
		_req_repeats_done += 1
	_refresh_gate()

#endregion

var _holding_key: bool = false;
func _input(event: InputEvent) -> void:
	# check if in list to prevent other keys from interfering
	if event is InputEventKey and event.physical_keycode in [Key.KEY_LEFT, Key.KEY_RIGHT, Key.KEY_ENTER]:
		# only register key once per press
		if !event.is_pressed():
			_holding_key = false
		elif !_holding_key:
			_holding_key = true
			match event.physical_keycode:
				Key.KEY_LEFT:
					on_back_pressed()
				Key.KEY_RIGHT:
					on_next_pressed()
				Key.KEY_ENTER:
					if current_page >= page_count() - 1:
						on_done_pressed()
					else:
						on_next_pressed()
