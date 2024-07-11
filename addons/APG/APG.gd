@tool
extends EditorPlugin

const GAME_SETTINGS = "APGGameSettings"
const USER_SETTINGS = "APGUserSettings"
const NETWORK = "APGNetwork"
const SURVEY_DB = "APGSurveyDB"

var _settings_dock: ScrollContainer
var _presets_dock: ScrollContainer


func _enter_tree():
	# Initialization of the plugin goes here.
	add_autoload_singleton(GAME_SETTINGS, "res://addons/APG/Scripts/AutoLoad/GameSettings.gd")
	add_autoload_singleton(USER_SETTINGS, "res://addons/APG/Scripts/AutoLoad/UserSettings.gd")
	add_autoload_singleton(NETWORK, "res://addons/APG/Scenes/AutoLoad/Network.tscn")
	add_autoload_singleton(SURVEY_DB, "res://addons/APG/Scenes/AutoLoad/SurveyDB.tscn")
	
	_settings_dock = preload("res://addons/APG/Scenes/SettingsDock.tscn").instantiate() as ScrollContainer
	_presets_dock = preload("res://addons/APG/Scenes/PresetsDock.tscn").instantiate() as ScrollContainer
	
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _settings_dock)
	add_control_to_dock(EditorPlugin.DOCK_SLOT_LEFT_BR, _presets_dock)
	
	(_settings_dock.get_node("Settings/GameSettings") as APGSettingsList).settings_saved.connect(
			(_presets_dock.get_node("Presets/GameSettingsPresets") as APGPresetList)._on_settings_saved)
	(_settings_dock.get_node("Settings/UserSettings") as APGSettingsList).settings_saved.connect(
			(_presets_dock.get_node("Presets/UserSettingsPresets") as APGPresetList)._on_settings_saved)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_autoload_singleton(GAME_SETTINGS)
	remove_autoload_singleton(USER_SETTINGS)
	remove_autoload_singleton(NETWORK)
	remove_autoload_singleton(SURVEY_DB)
	
	(_settings_dock.get_node("Settings/GameSettings") as APGSettingsList).settings_saved.disconnect(
			(_presets_dock.get_node("Presets/GameSettingsPresets") as APGPresetList)._on_settings_saved)
	(_settings_dock.get_node("Settings/UserSettings") as APGSettingsList).settings_saved.disconnect(
			(_presets_dock.get_node("Presets/UserSettingsPresets") as APGPresetList)._on_settings_saved)
	
	remove_control_from_docks(_settings_dock)
	remove_control_from_docks(_presets_dock)
	
	_settings_dock.queue_free()
	_presets_dock.queue_free()
