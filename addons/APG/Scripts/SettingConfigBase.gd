class_name APGSettingConfigBase
extends APGListItemUI

enum SettingType {INT, FLOAT, BOOL, STRING}

const TEXT_FIELD_EMPTY: String = "The field cannot be empty."
const TEXT_VALUE_DUPLICATE: String = "The value must be unique."
const TEXT_OPTION_EMPTY: String = "An option must be selected."
const TEXT_VALUE_INVALID: String = "Invalid value of selected type."
const TEXT_OK: String = "OK"

const TYPE_NAMES: Array[String] = ["int", "float", "bool", "String"]
const TYPE_ICONS: Array = [
	preload("res://addons/APG/Resources/Images/int.svg"),
	preload("res://addons/APG/Resources/Images/float.svg"),
	preload("res://addons/APG/Resources/Images/bool.svg"),
	preload("res://addons/APG/Resources/Images/String.svg"),
]

var previous_name: String = ""


func get_name_validator() -> Label:
	return null


func set_validator(validator: Label, text: String):
	validator.text = text
	validator.add_theme_color_override("font_color", Color.GREEN if text == TEXT_OK else Color.RED)


func _check_for_duplicates(text: String):
	var validator: Label = get_name_validator()
	var previous_duplicates: Array[APGSettingConfigBase] = []
	var current_duplicates: Array[APGSettingConfigBase] = []
	
	for child in get_parent().get_children():
		if child is APGSettingConfigBase:
			var setting_name: String = child.get_item_name()
			
			if not previous_name.is_empty() and setting_name == previous_name:
				previous_duplicates.append(child)
			elif setting_name == text:
				current_duplicates.append(child)
	
	if len(previous_duplicates) == 1:
		var previous_duplicate: APGSettingConfigBase = previous_duplicates[0]
		previous_duplicate.set_validator(previous_duplicate.get_name_validator(), TEXT_OK)
	
	if text.is_empty():
		set_validator(validator, TEXT_FIELD_EMPTY)
	elif len(current_duplicates) > 1:
		for current_duplicate in current_duplicates:
			current_duplicate.set_validator(current_duplicate.get_name_validator(), TEXT_VALUE_DUPLICATE)
	else:
		set_validator(validator, TEXT_OK)
	
	previous_name = text
	validity_changed.emit()


func _on_name_text_changed(new_text: String):
	_check_for_duplicates(new_text)


func _on_rearrange_button_down():
	grab_focus.call_deferred()


func _on_delete_button_up():
	get_parent().get_child(get_index() + 1).queue_free()
	queue_free()
