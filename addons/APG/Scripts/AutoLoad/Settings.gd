class_name APGSettings
extends Node
## The base class for the APGGameSettings and APGUserSettings autoload scripts.
##
## This script provides access to the [member settings] and [member presets] dictionaries
## as well as useful methods for manipulation with both settings and presets.

## Constants for accessing data file paths in subclasses.
enum SourceFile {SETTINGS, PRESETS}

## A dictionary mapping the names of settings to their definitions.
## Each definition is a dictionary with the keys [code]type[/code] where the
## numeric value can be [code]0[/code] for [code]int[/code], [code]1[/code]
## for [code]float[/code], [code]2[/code] for [code]bool[/code]
## or [code]3[/code] for [code]String[/code]; and [code]default[/code]
## where the value represents the setting's default value.
@onready var settings: Dictionary = _read_from_file(SourceFile.SETTINGS) :
	set(value):
		settings = value
		_save_to_file(SourceFile.SETTINGS)

## A dictionary mapping the names of setting presets to their definitions.
## Each definition is a dictionary mapping the names of settings
## to the values assigned to them when the preset is activated.
@onready var presets: Dictionary = _read_from_file(SourceFile.PRESETS) :
	set(value):
		presets = value
		_save_to_file(SourceFile.PRESETS)


## Returns the currently set value of the setting with name [param setting_name].
## If the setting has no set value, its default value is returned.
## If no setting with the given name exists, returns [code]null[/code].
func get_setting(setting_name: String) -> Variant:
	if not settings.has(setting_name):
		return null
	
	var setting: Dictionary = settings[setting_name]
	return setting.get("value", setting["default"])


## If a setting with name [param setting_name] exists,
## sets its value to [param value].
func set_setting(setting_name: String, value: Variant):
	if settings.has(setting_name):
		settings[setting_name]["value"] = value


## If a setting with name [param setting_name] exists,
## resets its value to its default.
func reset_default(setting_name: String):
	if settings.has(setting_name):
		settings[setting_name].erase("value")


## Resets the values of all defined settings to their defaults.
func reset_defaults():
	for setting in settings:
		reset_default(setting)


## Attempts to add a new preset with name [param preset_name].
## Returns [code]false[/code] if a preset with that name already exists,
## [code]true[/code] otherwise.
func create_preset(preset_name: String) -> bool:
	if presets.has(preset_name):
		return false
	presets[preset_name] = {}
	return true



## Attempts to delete a preset with name [param preset_name].
## Returns [code]true[/code] if a preset with that name existed and was deleted,
## [code]false[/code] otherwise.
func delete_preset(preset_name: String) -> bool:
	return presets.erase(preset_name)


## Attempts to activate a preset with name [param preset_name], setting the
## values of all settings in its definition to their defined values.
## The behavior for settings absent from the definition is specific to each
## subclass: APGGameSettings resets them to their default values, whereas
## APGUserSettings ignores them.
## If a preset with the given name does not exist, an error message is printed
## to the console.
func activate_preset(preset_name: String):
	if not presets.has(preset_name):
		printerr("Cannot activate nonexistent preset " + preset_name)
		return
	
	var preset: Dictionary = presets[preset_name]
	
	for setting_name in settings:
		if preset.has(setting_name):
			set_setting(setting_name, preset[setting_name])
		else:
			_handle_preset_absent_setting(setting_name)


## Returns a description string for a preset with name [param preset_name].
## Each setting is described on a separate line in the format
## [code]SettingName = SettingValue[/code]. Settings undefined in the preset
## are displayed with their default values followed by the text
## [code](default)[/code].
## If a preset with the given name does not exist, an error message is printed
## to the console.
func get_preset_description(preset_name: String) -> String:
	if not presets.has(preset_name):
		printerr("Cannot get description for nonexistent preset " + preset_name)
		return ""
	
	var preset: Dictionary = presets[preset_name]
	var description: String = preset_name + "\n\n"
	
	for setting_name in settings:
		if preset.has(setting_name):
			description += "%s = %s\n" % [setting_name, preset[setting_name]]
		else:
			description += "%s = %s (default)\n" % [setting_name, settings[setting_name]["default"]]
	return description


func _read_from_file(source: SourceFile) -> Dictionary:
	if not FileAccess.file_exists(_get_file_path(source)):
		return {}
	
	var file: FileAccess = FileAccess.open(_get_file_path(source), FileAccess.READ)
	var parsed_settings: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed_settings


func _save_to_file(source: SourceFile):
	var file: FileAccess = FileAccess.open(_get_file_path(source), FileAccess.WRITE)
	file.store_string(JSON.stringify(settings))
	file.close()


func _get_file_path(source: SourceFile) -> String:
	return ""


func _handle_preset_absent_setting(setting_name: String):
	pass
