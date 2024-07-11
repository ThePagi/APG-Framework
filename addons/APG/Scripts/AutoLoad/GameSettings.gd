extends APGSettings

const SETTINGS_PATH: String = "res://addons/APG/Resources/Data/GameSettings.json"
const PRESETS_PATH: String = "res://addons/APG/Resources/Data/GameSettingPresets.json"


func activate_preset(preset_name: String):
	_activate_preset_for_all.rpc(preset_name)


@rpc("call_local")
func _activate_preset_for_all(preset_name: String):
	super.activate_preset(preset_name)


func _get_file_path(source: SourceFile) -> String:
	return SETTINGS_PATH if source == SourceFile.SETTINGS else PRESETS_PATH

func _handle_preset_absent_setting(setting_name: String):
	reset_default(setting_name)
