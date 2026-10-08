@tool
extends EditorInspectorPlugin

const QUICK_ADD_HINT = "quick_add"

var _add_action_icon = EditorInterface.get_editor_theme().get_icon("Add","EditorIcons")
var _add_and_edit_icon = EditorInterface.get_editor_theme().get_icon("Edit","EditorIcons")
var _project_settings_editor: Node = _find_child_by_type(EditorInterface.get_base_control(), "ProjectSettingsEditor")
var _action_map_editor: Node = _project_settings_editor.get_child(0).get_child(1)

# Exported properties can be added to any scripts, so we need to parse all objects
func _can_handle(object: Object) -> bool: return true
func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if (hint_type == PROPERTY_HINT_INPUT_NAME) and (QUICK_ADD_HINT in hint_string.split(',')): _setup_property(object, name)
	return false

func _setup_property(object: Object, name: String) -> void:
	
	var property_inspector = await (func get_property_inspector(name: String) -> EditorProperty:
		# Workaround to get native EditorProperty from property name
		# Inject marker right after EditorProperty, to be able to cleanly get it as sibling of marker
		var marker := Control.new()
		add_property_editor(name, marker, true)
		await marker.ready
		marker.queue_free()# Marker is not needed afterwards 
		return marker.get_parent().get_child(marker.get_index() - 1)
	).call(name)
	var injected_buttons = _inject_buttons(property_inspector)
	
	# This connection will be closed safely on Property Inspector freeing
	property_inspector.property_changed.connect(_update_validity.bind(property_inspector, injected_buttons).unbind(4))
	
	var _update_on_input_settings_change: Callable = func(): 
		for setting in ProjectSettings.get_changed_settings():
			if setting.begins_with('input/'):
				_update_validity(property_inspector, injected_buttons)
				return
	ProjectSettings.settings_changed.connect(_update_on_input_settings_change)
	property_inspector.tree_exiting.connect(func(): ProjectSettings.settings_changed.disconnect(_update_on_input_settings_change))
	
	_update_validity(property_inspector, injected_buttons)

func _inject_buttons(property_inspector: EditorProperty) -> Array[Button]:
	var buttons: Array[Button] = []

	var object := property_inspector.get_edited_object()
	var property_name := property_inspector.get_edited_property()
		
	var add_action_button := Button.new(); \
		add_action_button.icon = _add_action_icon; \
		add_action_button.tooltip_text = "Add action"
	var add_action := func(object: Object, name: String):
		var property_value = object[name]
		_add_input_action(property_value)
	add_action_button.pressed.connect(add_action.bind(object, property_name))
	buttons.append(add_action_button)
	
	var add_and_edit_button := Button.new(); \
		add_and_edit_button.icon = _add_and_edit_icon; \
		add_and_edit_button.tooltip_text = "Add action & edit it"
	var add_action_and_event := func(object: Object, name: String):
		var property_value = object[name]
		_add_input_action(property_value)
		_open_add_action_event_dialog(property_value)
	add_and_edit_button.pressed.connect(add_action_and_event.bind(object, property_name))
	buttons.append(add_and_edit_button)
	
	for button in buttons:
		property_inspector.get_child(-1).add_child(button)
	return buttons
	
func _update_validity(property_inspector: EditorProperty, buttons_ref: Array[Button]):
	var object := property_inspector.get_edited_object()
	var property_name := property_inspector.get_edited_property()
	var property_value: String = object[property_name]
	
	var is_action = ProjectSettings.has_setting("input/" + property_value)
	property_inspector.draw_warning = not is_action 
	for button in buttons_ref:
		button.disabled = property_value.is_empty()
		button.visible = not is_action

func _add_input_action(action_name: String) -> void:
	# Hacky UI workaround used here because
	# ProjectSettings.set_setting() with input actions does not update UI until full engine restart (known bug)
	var line_edit: LineEdit = _action_map_editor.get_child(0).get_child(1).get_child(0)
	var add_button: Button = _action_map_editor.get_child(0).get_child(1).get_child(1)
	
	var text_backup = line_edit.text
	line_edit.text = action_name
	add_button.pressed.emit()
	line_edit.text = text_backup

# ATTENTION POINT IF ADD EVENT POPUP DOESN'T SHOW
func _open_add_action_event_dialog(action_name: String):
	_project_settings_editor.popup()
	(_project_settings_editor.get_child(0) as TabContainer).current_tab = 1
	
	var tree: Tree = _action_map_editor.get_child(0).get_child(2).get_child(0)
	var action_tree_item = _tree_search_recursive(tree.get_root(), action_name)

	tree.button_clicked.emit(action_tree_item, 2, 0, MOUSE_BUTTON_LEFT) # COLUMN AND INDEX HERE ARE HARDCODED AND PRONE TO CHANGES IN EDITOR

############################

func _tree_search_recursive(current_item: TreeItem, target_name: String) -> TreeItem:
	while current_item:
		if current_item.get_text(0) == target_name: return current_item
		if current_item.get_first_child():
			var found = _tree_search_recursive(current_item.get_first_child(), target_name)
			if found: return found
		current_item = current_item.get_next()
		
	return null

func _find_child_by_type(node: Node, type_name: String) -> Node:
	if node.get_class() == type_name: return node
	for child in node.get_children():
		var found = _find_child_by_type(child, type_name)
		if found: return found
	return null
