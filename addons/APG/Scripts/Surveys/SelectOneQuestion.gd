class_name APGSelectOneQuestion
extends APGSurveyQuestion

@export var checkbox_prefab: PackedScene
@export var h_parent: Node
@export var v_parent: Node

var button_group := ButtonGroup.new()
var _filled: bool


func _ready():
	button_group.pressed.connect(func(button: BaseButton): _filled = true)


func set_answers(answers: Array):
	var total_characters: int = answers.reduce(
			func(accum: int, answer: String): return accum + len(answer), 0)
	print(total_characters)
		
	for i in range(len(answers)):
		var answer: String = answers[i]
		var checkbox := checkbox_prefab.instantiate() as CheckBox
		
		checkbox.button_group = button_group
		checkbox.text = answer
		checkbox.name = str(i)
		
		if total_characters < 40:
			h_parent.add_child(checkbox)
		else:
			v_parent.add_child(checkbox)


func is_filled() -> bool:
	return _filled


func get_answer() -> int:
	return button_group.get_pressed_button().name.to_int()
