class_name APGSurveyQuestion
extends Node

@export var question_label: Label

var question_type: String


func set_question(question: String):
	question_label.text = question


func get_question() -> String:
	return question_label.text


func is_filled() -> bool:
	return false


func get_answer():
	return null
