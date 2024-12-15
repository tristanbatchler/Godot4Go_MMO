class_name Hiscores
extends ScrollContainer

var _scores: Array[int]

@onready var _vbox: VBoxContainer = $VBoxContainer
@onready var _entry_template: HBoxContainer = $VBoxContainer/HBoxContainer

func _ready() -> void:
	_entry_template.hide()

func set_hiscore(name: String, score: int, highlight: bool = false) -> void:
	remove_hiscore(name)
	_add_hiscore(name, score, highlight)

func _add_hiscore(name: String, score: int, highlight: bool) -> void:
	_scores.append(score)
	_scores.sort()
	var pos := len(_scores) - _scores.find(score) - 1
	
	var entry := _entry_template.duplicate()
	var name_label: Label = entry.get_child(0)
	var score_label: Label = entry.get_child(1)
	
	_vbox.add_child(entry)
	_vbox.move_child(entry, pos)
	
	name_label.text = name
	score_label.text = str(score)
	
	entry.show()
	
	if highlight:
		name_label.add_theme_color_override("font_color", Color.YELLOW)

func remove_hiscore(name: String) -> void:
	for i in range(len(_scores)):
		var entry := _vbox.get_child(i)
		var name_label: Label = entry.get_child(0)
		
		if name_label.text == name:
			_scores.remove_at(len(_scores) - i - 1)
			
			entry.free()
			return

func clear_hiscores() -> void:
	_scores.clear()
	for entry in _vbox.get_children():
		if entry != _entry_template:
			entry.free()
