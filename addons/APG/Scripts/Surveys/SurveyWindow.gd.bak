class_name APGSurveyWindow
extends Node

signal on_submit(answers)

@export var questions_container: Node
@export var submit_button: Button
@export var error_label: Label

var uid: String

var _questions: Array = []
var _unsubmitted: APGSurveyQuestion = null


func _ready():
	submit_button.pressed.connect(_try_submit)


func _process(_delta: float):
	if _unsubmitted and _unsubmitted.is_filled():
		_unsubmitted = null
		error_label.text = ""


func add_question(question: APGSurveyQuestion):
	_questions.append(question)
	questions_container.add_child(question)


func _try_submit():
	var answers: Array = []
	
	for question in _questions:
		if not question.is_filled():
			_unsubmitted = question
			error_label.text = "Please answer '" + question.get_question() + "'"
			return
		answers.append({question.question_type : question.get_answer()})
	on_submit.emit([uid, answers])
