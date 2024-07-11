class_name APGSelectMultipleQuestion
extends APGSurveyQuestion

@export var checkbox_prefab: PackedScene

var _selected: Array = []


func set_answers(answers: Array):
	for i in range(len(answers)):
		var answer: String = answers[i]
		var checkbox := checkbox_prefab.instantiate() as CheckBox
		var index: int = i
		
		checkbox.text = answer
		checkbox.name = str(index)
		
		var on_toggled: Callable = func(checked: bool):
			if checked:
				_selected.append(index)
			else:
				_selected.erase(index)
		
		checkbox.toggled.connect(on_toggled)
		add_child(checkbox)


func is_filled() -> bool:
	return not _selected.is_empty()


func get_answer() -> Array:
	return _selected
