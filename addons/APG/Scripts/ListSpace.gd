@tool
extends Control


func _can_drop_data(_at_position: Vector2, data):
	return data is Control and get_parent().is_ancestor_of(data)


func _drop_data(_at_position: Vector2, data):
	var configs_list := get_parent() as VBoxContainer
	var space_above: Control = configs_list.get_child(data.get_index() - 1)
	var index: int = get_index()
	
	configs_list.move_child(data, index)
	configs_list.move_child(space_above, index)
