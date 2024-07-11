extends APGSettings

const SETTINGS_PATH: String = "res://addons/APG/Resources/Data/UserSettings.json"
const PRESETS_PATH: String = "res://addons/APG/Resources/Data/UserSettingPresets.json"


func _get_file_path(source: SourceFile) -> String:
	return SETTINGS_PATH if source == SourceFile.SETTINGS else PRESETS_PATH
