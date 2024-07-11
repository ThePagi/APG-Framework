@tool
class_name APGSettingConfig
extends APGSettingConfigBase


func _ready():
	super._ready()
	
	var type_selector: OptionButton = $Columns/Fields/Type as OptionButton
	type_selector.clear()
	
	for type in SettingType.values():
		type_selector.add_icon_item(TYPE_ICONS[type], TYPE_NAMES[type])
	
	$Columns/Rearrange.root = self
	
	type_selector.selected = -1
	
	set_validator(get_name_validator(), TEXT_FIELD_EMPTY)
	set_validator(get_type_validator(), TEXT_OPTION_EMPTY)
	
	validity_changed.emit()


func set_fields(item_name: String, data: Dictionary):
	var type: int = data["type"]
	var default: Variant = data["default"]
	
	$Columns/Fields/Name.text = item_name
	$Columns/Fields/Type.selected = type
	_on_type_item_selected(type)
	
	if type == SettingType.BOOL:
		$Columns/Fields/Default.button_pressed = default
	else:
		$Columns/Fields/Default.text = str(default)
	
	set_validator(get_name_validator(), TEXT_OK)
	set_validator(get_default_validator(), TEXT_OK)


func get_item_name() -> String:
	return $Columns/Fields/Name.text


func get_type() -> int:
	return $Columns/Fields/Type.selected


func get_default() -> Variant:
	var default = $Columns/Fields/Default
	
	match $Columns/Fields/Type.selected:
		SettingType.INT:
			return default.text.to_int()
		SettingType.FLOAT:
			return default.text.to_float()
		SettingType.BOOL:
			return default.button_pressed
		SettingType.STRING:
			return default.text
		_:
			return null


func get_name_validator() -> Label:
	return $Columns/Validators/Name


func get_type_validator() -> Label:
	return $Columns/Validators/Type


func get_default_validator() -> Label:
	return $Columns/Validators/Default


func is_valid() -> bool:
	return (
			get_name_validator().text == TEXT_OK
			and get_type_validator().text == TEXT_OK
			and get_default_validator().text == TEXT_OK
	)


func _on_type_item_selected(index: int):
	var default: Control = $Columns/Fields/Default as Control
	var default_validator: Label = get_default_validator()
	var new_default: Control
	
	match index:
		SettingType.INT:
			new_default = LineEdit.new()
			new_default.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			new_default.text_changed.connect(_on_default_text_changed)
			set_validator(default_validator, TEXT_VALUE_INVALID)
		SettingType.FLOAT:
			new_default = LineEdit.new()
			new_default.alignment = HORIZONTAL_ALIGNMENT_RIGHT
			new_default.text_changed.connect(_on_default_text_changed)
			set_validator(default_validator, TEXT_VALUE_INVALID)
		SettingType.BOOL:
			new_default = CheckBox.new()
			new_default.text = "On"
			set_validator(default_validator, TEXT_OK)
		SettingType.STRING:
			new_default = LineEdit.new()
			set_validator(default_validator, TEXT_OK)
	
	default.replace_by(new_default)
	new_default.name = "Default"
	
	$Columns/FieldNames/Default.show()
	default_validator.show()
	
	set_validator(get_type_validator(), TEXT_OK)
	validity_changed.emit()


func _on_default_text_changed(new_text: String):
	var validator: Label = get_default_validator()
	
	match get_type():
		SettingType.INT:
			set_validator(validator, TEXT_OK if new_text.is_valid_int() else TEXT_VALUE_INVALID)
		SettingType.FLOAT:
			set_validator(validator, TEXT_OK if new_text.is_valid_float() else TEXT_VALUE_INVALID)
	
	validity_changed.emit()
