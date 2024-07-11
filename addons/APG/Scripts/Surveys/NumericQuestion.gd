class_name APGNumericQuestion
extends APGSurveyQuestion

@export var input: SpinBox

var _filled: bool = false


func is_filled() -> bool:
	return _filled


func get_answer() -> float:
	return input.value


func set_answers(minmax: Array):
	input.min_value = minmax[0]
	input.max_value = minmax[1]


func _on_spin_box_value_changed(value: int):
	_filled = true
