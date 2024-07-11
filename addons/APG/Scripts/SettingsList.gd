@tool
class_name APGSettingsList
extends APGListUI

signal settings_saved

enum SettingsType {GAME, USER}

const SETTING_CONFIG = preload("res://addons/APG/Scenes/SettingConfig.tscn")

const SETTINGS_NAMES: Array[String] = ["Game Settings", "User Settings"]

@export var settings_type: SettingsType


func _ready():
	super._ready()
	$Collapse.text = SETTINGS_NAMES[settings_type]


func get_list() -> VBoxContainer:
	return $List


func get_collapse_button() -> Button:
	return $Collapse


func get_add_button() -> Button:
	return $AddElement


func get_save_button() -> Button:
	return $Save


func _get_data_path() -> String:
	return SETTINGS_PATHS[settings_type]


func _get_item_template() -> PackedScene:
	return SETTING_CONFIG


func _init_item(item: APGListItemUI, item_name: String, item_data: Dictionary):
	super._init_item(item, item_name, item_data)
	_connect_item_signal(item)


func _get_item_data(item: APGListItemUI) -> Dictionary:
	if not item is APGSettingConfig:
		return {}
	return {
		type = item.get_type(),
		default = item.get_default(),
	}


func _on_collapse_button_up():
	super._on_collapse_button_up()
	$Save.visible = $List.visible


func _on_save_button_up():
	super._on_save_button_up()
	settings_saved.emit()
