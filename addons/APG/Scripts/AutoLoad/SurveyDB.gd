extends Node

var db := JSON.parse_string(FileAccess.open("res://addons/APG/Resources/Data/survey.json",
		FileAccess.READ).get_as_text()) as Dictionary

@export var survey_window := preload("res://addons/APG/Scenes/Surveys/SurveyWindow.tscn")
@export var open_question := preload("res://addons/APG/Scenes/Surveys/OpenQuestion.tscn")
@export var numeric_question := preload("res://addons/APG/Scenes/Surveys/NumericQuestion.tscn")
@export var single_choice_question := preload("res://addons/APG/Scenes/Surveys/SelectOneQuestion.tscn")
@export var likert_question := preload("res://addons/APG/Scenes/Surveys/LikertQuestion.tscn")
@export var multiple_choice_question := preload("res://addons/APG/Scenes/Surveys/SelectMultipleQuestion.tscn")


func _ready():
	APGNetwork.survey_received.connect(_on_survey)


func _on_survey(uid: String):
	var window := survey_window.instantiate() as APGSurveyWindow
	window.on_submit.connect(_submit)
	window.on_submit.connect(func(answers: Array): window.queue_free())
	window.uid = uid
	add_child(window)
	
	if uid not in db:
		printerr("Key " + uid + " not in survey database!")
		return
	var questions = db[uid]
	for question in questions["entries"]:
		var instance: APGSurveyQuestion = get_question_instance(question)
		window.add_question(instance)


func _submit(answers: Array):
	APGNetwork.send_msg_to_signal(APGNetwork.MsgType.SURVEY,
			JSON.stringify(answers))


func get_question_instance(question: Dictionary) -> APGSurveyQuestion:
	var instance: APGSurveyQuestion = null
	if question["answer_type"] is String and question["answer_type"] == "Open":
		instance = open_question.instantiate() as APGOpenQuestion
		instance.question_type = "Open"
	elif "Numeric" in question["answer_type"]:
		instance = numeric_question.instantiate() as APGNumericQuestion
		instance.set_answers(question["answer_type"]["Numeric"])
		instance.question_type = "Numeric"
	elif "Likert5" in question["answer_type"]:
		instance = likert_question.instantiate() as APGSelectOneQuestion
		instance.set_answers(question["answer_type"]["Likert5"])
		instance.question_type = "Likert5"
	elif "Likert7" in question["answer_type"]:
		instance = likert_question.instantiate() as APGSelectOneQuestion
		instance.set_answers(question["answer_type"]["Likert7"])
		instance.question_type = "Likert7"
	elif "SelectOne" in question["answer_type"]:
		instance = single_choice_question.instantiate() as APGSelectOneQuestion
		instance.set_answers(question["answer_type"]["SelectOne"])
		instance.question_type = "SelectOne"
	elif "SelectMultiple" in question["answer_type"]:
		instance = multiple_choice_question.instantiate() as APGSelectMultipleQuestion
		instance.set_answers(question["answer_type"]["SelectMultiple"])
		instance.question_type = "SelectMultiple"
	else:
		printerr("Unknown answer type: ", question)
		return null
	
	instance.set_question(question["question"])
	return instance
