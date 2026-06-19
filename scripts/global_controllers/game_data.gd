extends Node

const DATA_PATH = "user://data.bin"

var data = {
	"level_scores": {}
}

func _ready():
	if FileAccess.file_exists(DATA_PATH):
		var file = FileAccess.open(DATA_PATH, FileAccess.READ)
		data = file.get_var(true)
		file.close()

func check_and_save_level_score(level: int, time: float, score: int, grade: String):
	if data["level_scores"].has(level):
		var current_score = data["level_scores"][level]
		
		print("%s %s" % [time, current_score["time"]])
		
		var grades = ["W", "S", "A", "B", "C", "D", "F"]
		
		data["level_scores"][level] = {
			"time": min(time, current_score["time"]),
			"score": max(score, current_score["score"]),
			"grade":
				"W" if "W" in [current_score["grade"], grade] else 
				"S" if "S" in [current_score["grade"], grade] else
				grade if grades.find(grade) < grades.find(current_score["grade"]) else current_score["grade"]
		}
	else:
		data["level_scores"][level] = {
			"time": time,
			"score": score,
			"grade": grade,
		}
	_save()

func is_level_passed(id: int = LevelController.current_level_id) -> bool:
	return data["level_scores"].has(id)

func _save() -> void:
	var file = FileAccess.open(DATA_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()
