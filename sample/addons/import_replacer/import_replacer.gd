@tool
extends EditorPlugin


var import_plugin : EditorScenePostImportPlugin = null


func _enter_tree() -> void:
	import_plugin = preload("res://addons/import_replacer/import_plugin.gd").new()
	add_scene_post_import_plugin(import_plugin)


func _exit_tree() -> void:
	remove_scene_post_import_plugin(import_plugin)
	import_plugin = null
