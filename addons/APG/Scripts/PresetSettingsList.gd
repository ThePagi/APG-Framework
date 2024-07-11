@tool
class_name APGPresetSettingsList
extends APGListUI

signal validity_changed

const PRESET_SETTING_CONFIG = preload("res://addons/APG/Scenes/PresetSettingConfig.tscn")


func _ready():
	pass


func get_list() -> VBoxContainer:
	return $List


func get_collapse_button() -> Button:
	return $Collapse


func get_add_button() -> Button:
	return $AddElement


func get_preset_settings() -> Dictionary:
	var settings: Dictionary = {}
	
	for child in $List.get_children():
		if child is APGListItemUI:
			settings[child.get_setting()] = child.get_value()
	
	return settings


func set_preset_settings(preset_settings: Dictionary):
	for setting in preset_settings:
		_init_item(_add_new_item(false), setting, preset_settings)


func is_valid() -> bool:
	return $List.get_children().all(_child_is_valid)


func _child_is_valid(child: Node) -> bool:
	return not child is APGListItemUI or child.is_valid()


func _get_item_template() -> PackedScene:
	return PRESET_SETTING_CONFIG


func _on_item_validity_changed():
	validity_changed.emit()
