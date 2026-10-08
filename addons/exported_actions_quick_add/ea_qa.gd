@tool
extends EditorPlugin

var inspector_plugin: EditorInspectorPlugin = \
	preload("res://addons/exported_actions_quick_add/inspector_plugin.gd").new()

func _enter_tree() -> void:
	add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)
