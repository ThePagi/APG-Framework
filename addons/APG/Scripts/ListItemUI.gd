class_name APGListItemUI
extends PanelContainer

signal validity_changed

const STYLE_DEFAULT = preload("res://addons/APG/Resources/Styles/ListItemDefault.tres")
const STYLE_FOCUSED = preload("res://addons/APG/Resources/Styles/ListItemFocused.tres")


func _ready():
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	tree_exited.connect(_on_tree_exited)


func get_item_name() -> String:
	return ""


func set_fields(item_name: String, data: Dictionary):
	pass


func is_valid() -> bool:
	return false


func _on_focus_entered():
	add_theme_stylebox_override("panel", STYLE_FOCUSED)


func _on_focus_exited():
	add_theme_stylebox_override("panel", STYLE_DEFAULT)


func _on_tree_exited():
	validity_changed.emit()
