class_name APGListUI
extends VBoxContainer

const COLLAPSE_ICON = preload("res://addons/APG/Resources/Images/Collapse.svg")
const FORWARD_ICON = preload("res://addons/APG/Resources/Images/Forward.svg")

const LIST_SPACE = preload("res://addons/APG/Scenes/ListSpace.tscn")

const SETTINGS_PATHS: Array[String] = [
	"res://addons/APG/Resources/Data/GameSettings.json",
	"res://addons/APG/Resources/Data/UserSettings.json",
]


func _ready():
	var list_data: Dictionary = _load_data(_get_data_path())
	
	for item_name in list_data:
		_init_item(_add_new_item(false), item_name, list_data[item_name])


func get_list() -> VBoxContainer:
	return null 


func get_collapse_button() -> Button:
	return null


func get_add_button() -> Button:
	return null


func get_save_button() -> Button:
	return null


func _get_data_path() -> String:
	return ""


func _load_data(path: String) -> Dictionary:
	var data: Dictionary = {}
	
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
		file.close()
	
	return data


func _get_item_template() -> PackedScene:
	return null


func _connect_item_signal(item: APGListItemUI):
	item.validity_changed.connect(_on_item_validity_changed)


func _add_new_item(connect_signal: bool = true) -> APGListItemUI:
	var new_item := _get_item_template().instantiate() as APGListItemUI
	
	if connect_signal:
		_connect_item_signal(new_item)
	
	$List.add_child(new_item)
	$List.add_child(LIST_SPACE.instantiate())
	
	return new_item


func _init_item(item: APGListItemUI, item_name: String, item_data: Dictionary):
	item.set_fields(item_name, item_data)


func _get_item_data(item: APGListItemUI) -> Dictionary:
	return {}


func _on_collapse_button_up():
	var list: VBoxContainer = get_list()
	
	list.visible = not list.visible
	get_collapse_button().icon = COLLAPSE_ICON if list.visible else FORWARD_ICON
	get_add_button().visible = list.visible


func _on_add_element_button_up():
	_add_new_item()


func _on_save_button_up():
	var items: Dictionary = {}
	
	for child in get_list().get_children():
		if child is APGListItemUI:
			var item_data: Dictionary = _get_item_data(child as APGListItemUI)
			items[child.get_item_name()] = item_data
	
	var file: FileAccess = FileAccess.open(_get_data_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(items, "", false, true))
	file.close()


func _is_invalid_item(node: Node) -> bool:
	return node is APGListItemUI and not (node as APGListItemUI).is_valid()


func _on_item_validity_changed():
	get_save_button().disabled = get_list().get_children().any(_is_invalid_item)
