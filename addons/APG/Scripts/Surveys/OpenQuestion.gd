class_name APGOpenQuestion
extends APGSurveyQuestion

@export var input: TextEdit


func is_filled() -> bool:
	return not input.text.is_empty()


func get_answer() -> String:
	return input.text
