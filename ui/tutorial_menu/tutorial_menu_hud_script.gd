class_name TutorialMenu extends CanvasLayer

@onready var page_count_label: Label = %PageCount
@onready var illustration: TextureRect = %Illustration
@onready var description_label: RichTextLabel = %Description
@onready var back_button: Button = %Back
@onready var next_button: Button = %Next
@onready var done_button: Button = %Done

var pages: Array[TutorialPageData] = []

var current_page: int = 0


func set_pages(content : Array[TutorialPageData]) -> void:
	pages = content;
	
	update_page()

func on_back_pressed() -> void:
	if current_page <= 0:
		return
	current_page -= 1
	update_page()

func on_next_pressed() -> void:
	
	print("lol")
	
	if current_page >= page_count() - 1:
		return
		
	current_page += 1
	update_page()

func on_done_pressed() -> void:
	LevelController.close_tutorial()

func update_page() -> void:
	var page_count = page_count()
	page_count_label.text = "%s %d/%d" % [pages[current_page].title, current_page + 1, page_count]

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
	done_button.disabled = current_page != page_count - 1

func page_count() -> int:
	return max(pages.size(), 1)
