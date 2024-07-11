@tool
class_name APGPresetConfig
extends APGSettingConfigBase


func _ready():
	super._ready()
	
	$Columns/Rearrange.root = self
	$Columns/Rows/PresetSettingsList.validity_changed.connect(_on_settings_list_validity_changed)
	
	set_validator(get_name_validator(), TEXT_FIELD_EMPTY)
	validity_changed.emit()


func set_fields(item_name: String, data: Dictionary):
	$Columns/Rows/Columns/Fields/Name.text = item_name
	set_preset_settings(data)
	set_validator(get_name_validator(), TEXT_OK)


func get_item_name() -> String:
	return $Columns/Rows/Columns/Fields/Name.text


func get_preset_settings() -> Dictionary:
	return $Columns/Rows/PresetSettingsList.get_preset_settings()


func set_preset_settings(settings: Dictionary):
	$Columns/Rows/PresetSettingsList.set_preset_settings(settings)


func get_name_validator() -> Label:
	return $Columns/Rows/Columns/Validators/Name


func is_valid() -> bool:
	return get_name_validator().text == TEXT_OK and $Columns/Rows/PresetSettingsList.is_valid()


func _on_settings_list_validity_changed():
	validity_changed.emit()
