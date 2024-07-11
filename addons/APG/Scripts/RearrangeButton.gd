@tool
extends Button

var root: Control


func _get_drag_data(_at_position: Vector2):
	return root
