@tool
class_name APGPresetList
extends APGListUI

enum PresetType {GAME, USER}

const PRESET_CONFIG = preload("res://addons/APG/Scenes/PresetConfig.tscn")

const PRESETS_NAMES: Array[String] = ["Game Settings Presets", "User Settings Presets"]
const PRESETS_PATHS: Array[String] = [
	"res://addons/APG/Resources/Data/GameSettingPresets.json",
	"res://addons/APG/Resources/Data/UserSettingPresets.json",
]

@export var preset_type: PresetType

var settings: Dictionary


func _enter_tree():
	_on_settings_saved(false)


func _ready():
	super._ready()
	$Collapse.text = PRESETS_NAMES[preset_type]


func get_list() -> VBoxContainer:
	return $List


func get_collapse_button() -> Button:
	return $Collapse


func get_add_button() -> Button:
	return $AddElement


func get_save_button() -> Button:
	return $Save


func _get_data_path() -> String:
	return PRESETS_PATHS[preset_type]


func _get_item_template() -> PackedScene:
	return PRESET_CONFIG


func _init_item(item: APGListItemUI, item_name: String, item_data: Dictionary):
	super._init_item(item, item_name, item_data)
	_connect_item_signal(item)


func _get_item_data(item: APGListItemUI) -> Dictionary:
	if not item is APGPresetConfig:
		return {}
	return item.get_preset_settings()


func _on_collapse_button_up():
	super._on_collapse_button_up()
	$Save.visible = $List.visible


func _reset_presets_file():
	var file: FileAccess = FileAccess.open(PRESETS_PATHS[preset_type], FileAccess.WRITE)
	file.store_string("{}")
	file.close()


func _on_settings_saved(reset_list: bool = true):
	settings = _load_data(SETTINGS_PATHS[preset_type])
	
	if reset_list:
		for child in $List.get_children():
			if child is APGListItemUI:
				child._on_delete_button_up()
		_reset_presets_file()
