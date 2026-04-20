extends Control

@onready var page_count_label: Label = %PageCount
@onready var illustration: TextureRect = %Illustration
@onready var description_label: Label = %Description
@onready var back_button: Button = %Back
@onready var next_button: Button = %Next
@onready var done_button: Button = %Done

@export var pages: Array[TutorialPageData] = []

var current_page: int = 0

func _ready() -> void:
	_update_page()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_back_pressed() -> void:
	if current_page <= 0:
		return
	current_page -= 1
	_update_page()

func _on_next_pressed() -> void:
	if current_page >= _page_count() - 1:
		return
	current_page += 1
	_update_page()

func _on_done_pressed() -> void:
	_close_tutorial()

func _update_page() -> void:
	var page_count = _page_count()
	page_count_label.text = "%d/%d" % [current_page + 1, page_count]

	if pages.size() > current_page and pages[current_page].image != null:
		illustration.texture = pages[current_page].image
		illustration.visible = true
	else:
		illustration.texture = null
		illustration.visible = false

	if pages.size() > current_page:
		description_label.text = pages[current_page].description
	else:
		description_label.text = ""

	back_button.disabled = current_page == 0
	next_button.disabled = current_page >= page_count - 1
	done_button.visible = current_page == page_count - 1
	done_button.disabled = current_page != page_count - 1

func _page_count() -> int:
	return max(pages.size(), 1)

func _close_tutorial() -> void:
	LevelController.unfreeze_game()
	LevelController.unfreeze_timer()
	LevelController.set_tutorial_open(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()


func _on_prev_button_pressed() -> void:
	pass # Replace with function body.


func _on_next_button_pressed() -> void:
	pass # Replace with function body.


func _on_done_button_pressed() -> void:
	pass # Replace with function body.
