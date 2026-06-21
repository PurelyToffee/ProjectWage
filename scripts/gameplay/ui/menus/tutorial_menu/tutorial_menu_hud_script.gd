class_name TutorialMenu extends CanvasLayer

@onready var page_count_label: Label = %PageCount
@onready var illustration: TextureRect = %Illustration
@onready var description_label: RichTextLabel = %Description
@onready var back_button: Button = %Back
@onready var next_button: Button = %Next
@onready var done_button: Button = %Done
@onready var video_player: VideoStreamPlayer = %TutorialVideo
var video: VideoStreamTheora

var pages: Array[TutorialPageData] = []

var current_page: int = 0

func _ready() -> void:
	video_player.visible = video_player.stream != null
	illustration.visible = illustration.texture != null

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
		
	current_page += 1
	update_page()

func on_done_pressed() -> void:
	LevelController.close_tutorial()

func format_colors(text : String) -> String:
	
	text = text.replace("CRed", Color("D52224").to_html());
	text = text.replace("Highlight1", Color("FCD653FF").to_html());
	
	return text

func update_page() -> void:
	var page_count = page_count()
	page_count_label.text = "%s %d/%d" % [pages[current_page].title, current_page + 1, page_count]

	#var media = pages[current_page].media
	var media = pages[current_page].video
	if media == null:
		media = pages[current_page].image

	if media == null:
		pass
	elif media is VideoStream:
		# prevent video from restarting on page change
		if media != video_player.stream:
			video_player.stream = media
			video_player.visible = true
			video_player.play()
			illustration.texture = null
			illustration.visible = false
	elif media is Texture2D:
		illustration.texture = media
		illustration.visible = true
		video_player.stream = null
		video_player.visible = false
	else:
		push_error("TutorialPageData media is not VideoStream nor Texture2D")

	if pages.size() > current_page:
		description_label.text = format_colors(pages[current_page].description);
	else:
		description_label.text = ""

	back_button.disabled = current_page == 0
	next_button.disabled = current_page >= page_count - 1
	done_button.disabled = current_page != page_count - 1

func page_count() -> int:
	return max(pages.size(), 1)

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
