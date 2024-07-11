@tool
class_name APGPresetSettingConfig
extends APGSettingConfigBase

var settings: Dictionary :
	get:
		return get_parent().get_parent().get_parent().get_parent() \
				.get_parent().get_parent().get_parent().settings


func _ready():
	super._ready()
	
	var setting_selector: OptionButton = $Columns/Fields/Setting as OptionButton
	setting_selector.clear()
	
	for setting_name in settings:
		var setting: Dictionary = settings[setting_name]
		setting_selector.add_icon_item(TYPE_ICONS[setting["type"]], setting_name)
	
	if settings.is_empty():
		setting_selector.add_item("No settings available")
		setting_selector.set_item_disabled(0, true)
	
	$Columns/Rearrange.root = self
	
	setting_selector.selected = -1
	
	set_validator(get_setting_validator(), TEXT_OPTION_EMPTY)
	set_validator(get_value_validator(), TEXT_VALUE_INVALID)
	
	validity_changed.emit()


func set_fields(item_name: String, data: Dictionary):
	var setting: OptionButton = $Columns/Fields/Setting as OptionButton
	
	setting.selected = settings.keys().find(item_name)
	_on_setting_item_selected(setting.selected)
	$Columns/Fields/Value.text = str(data[item_name])
	
	set_validator(get_setting_validator(), TEXT_OK)
	set_validator(get_value_validator(), TEXT_OK)


func get_setting(index: int = -1) -> String:
	if index == -1:
		index = $Columns/Fields/Setting.selected
	return $Columns/Fields/Setting.get_item_text(index)


func get_item_name() -> String:
	return get_setting()


func get_value() -> Variant:
	var value: Control = $Columns/Fields/Value
	
	match int(settings[get_setting()]["type"]):
		SettingType.INT:
			return value.text.to_int()
		SettingType.FLOAT:
			return value.text.to_float()
		SettingType.BOOL:
			return value.button_pressed
		SettingType.STRING:
			return value.text
		_:
			return null


func get_setting_validator() -> Label:
	return $Columns/Validators/Setting


func get_value_validator() -> Label:
	return $Columns/Validators/Value


func get_name_validator() -> Label:
	return get_setting_validator()


func is_valid() -> bool:
	return (
			get_setting_validator().text == TEXT_OK
			and get_value_validator().text == TEXT_OK
	)


func _on_setting_item_selected(index: int):
	var value: Control = $Columns/Fields/Value as Control
	var value_validator: Label = get_value_validator()
	var setting: Dictionary = settings[get_setting(index)]
	var type: int = setting["type"]
	var default: Variant = setting["default"]
	var new_value: Control
	
	match type:
		SettingType.INT:
			new_value = LineEdit.new()
			new_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			new_value.text = str(default)
			new_value.text_changed.connect(_on_value_text_changed)
		SettingType.FLOAT:
			new_value = LineEdit.new()
			new_value.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			new_value.text = str(default)
			new_value.text_changed.connect(_on_value_text_changed)
		SettingType.BOOL:
			new_value = CheckBox.new()
			new_value.button_pressed = default
			new_value.text = "On"
		SettingType.STRING:
			new_value = LineEdit.new()
			new_value.text = default
	
	set_validator(value_validator, TEXT_OK)
	value.replace_by(new_value)
	new_value.name = "Value"
	
	$Columns/FieldNames/Value.show()
	value_validator.show()
	
	_check_for_duplicates($Columns/Fields/Setting.get_item_text(index))


func _on_value_text_changed(new_text: String):
	var validator: Label = get_value_validator()
	
	match settings[get_setting()]["type"]:
		SettingType.INT:
			set_validator(validator, TEXT_OK if new_text.is_valid_int() else TEXT_VALUE_INVALID)
		SettingType.FLOAT:
			set_validator(validator, TEXT_OK if new_text.is_valid_float() else TEXT_VALUE_INVALID)
	
	validity_changed.emit()
