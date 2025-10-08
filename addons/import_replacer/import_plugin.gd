@tool
extends EditorScenePostImportPlugin


const PRUNE_WRAPPER_SETTINGS := "addons/import_replacer/always_prune_wrapper" ## Helpful to remove empty Node3D's from like Blender AssetBrowser collection links, which creates empties

const IR_PATH = "ir_path"
const IR_RES = "ir_res"
const IR_PROPERTY = "ir_prop"
const IR_VALUE = "ir_val"

var main_scene: Node
var file_path: String

var _plugin: EditorPlugin


func _get_import_options(path: String) -> void:
	add_import_option("file_path", path)
	file_path = path
	
	if not ProjectSettings.has_setting(PRUNE_WRAPPER_SETTINGS):
		ProjectSettings.set_setting(PRUNE_WRAPPER_SETTINGS, true)
		ProjectSettings.set_setting(PRUNE_WRAPPER_SETTINGS, true)


func _post_process(scene: Node) -> void:
	print("[IMPORT REPLACER] Processing: " + file_path)
	
	main_scene = scene
	iterate(scene)
	
	if ProjectSettings.get_setting(PRUNE_WRAPPER_SETTINGS):
		print("[IMPORT REPLACER] Prune Wrappers: " + file_path)
		
		_prune_node3d_wrappers(scene)
	
	print("[IMPORT REPLACER] Finished: " + file_path)


func iterate(node: Node) -> void:
	if node != null:
		if node.name.begins_with("IR"):
			var args := _split_args(node.name)
			var method: String = args[0]
			args.remove_at(0)
			
			if method == "REPLACE": # change an empty with a different object
				var path: String = _get_full_path(node)
				
				_set_node(node, path)
			
			elif method == "PROP_PATH": # change the property and load into it something (e.g. Material)
				var path: String = _get_full_res_path(node)
				var property: String = _get_meta_value(node, IR_PROPERTY)
				
				_set_prop(node, property, load(path))
			
			elif method == "PROPS_VAL": # change the property and set a specific value of multiple values at the same time
				_set_props(node)
			
			elif method == "SCRIPT": # add script to node - always expecting a .gd file
				var path: String = _get_full_script_path(node)
				var script_res := load(path)
				var parent = node.get_parent()
				
				parent.set_script(script_res)
			
			elif method == "GROUP": # add node to group specified
				var group: String = _get_meta_value(node, IR_VALUE)
				var parent = node.get_parent()
				
				parent.add_to_group(group, true)
			
			elif method == "REPLACE_TYPE": # replace the object with a different one. Children will be continued
				var new_type: String = _get_meta_value(node, IR_VALUE)
				
				_replace_node(node, new_type)
			
			else:
				printerr("[IMPORT REPLACER] found invalid method: " + method + " (" + node.name + ")")
			
			
			_delete_node(node)
		
		for child in node.get_children():
			iterate(child)


func _get_custom_props(node: Node) -> Dictionary:
	if not node.has_meta("extras"):
		printerr("No Custom Properties in node '" + node.name + "' found. Make sure to export them too!")
	
	return node.get_meta("extras")


func _split_args(name: String) -> PackedStringArray:
	if not name.contains("-"):
		printerr("Found IR invalid naming convention use. See docs!")
	
	var args := name.split("-")
	args.remove_at(0) # we don't care about "IR"
	return args


func _get_meta_value(node: Node, path: String) -> Variant:
	var extras := _get_custom_props(node)
	
	if not extras.has(path):
		printerr("Key '" + path + "' in node '" + node.name + "' not existing")
	return extras.get(path)


func _get_full_path(node: Node) -> String:
	var path = _get_meta_value(node, IR_PATH)
	return _get_path(path)


func _get_path(path: String) -> String:
	return "%s.tscn" % [path]


func _get_full_res_path(node: Node) -> String:
	var path = _get_meta_value(node, IR_RES)
	return _get_res_path(path)


func _get_res_path(path: String) -> String:
	return "%s.tres" % [path]


func _get_full_script_path(node: Node) -> String:
	var path = _get_meta_value(node, IR_PATH)
	return _get_script_path(path)


func _get_script_path(path: String) -> String:
	return "%s.gd" % [path]


func _set_props(node: Node) -> void:
	var extras := _get_custom_props(node)
	var prop_res: Dictionary = {}
	
	for key in extras.keys():
		var parts: PackedStringArray = str(key).split("/")
		
		if parts.size() == 2:
			var name := parts[0]
			var idx := int(parts[1])
			
			if not prop_res.has(idx):
				prop_res[idx] = {}
			
			if name == IR_PROPERTY:
				prop_res[idx][IR_PROPERTY] = extras[key]
			elif name == IR_VALUE:
				prop_res[idx][IR_VALUE] = extras[key]
	
	for key in prop_res.keys():
		var item: Dictionary = prop_res.get(key)
		
		_set_prop(node, item.get(IR_PROPERTY), item.get(IR_VALUE))


func _set_prop(node: Node, property: String, value: Variant) -> void:
	node.get_parent().set(property, value)


func _set_node(node: Node, path: String) -> void:
	var inst = load(path).instantiate()
	var parent = node.get_parent()
	parent.add_child(inst)
	
	inst.transform = node.transform
	inst.set_owner(main_scene)


func _replace_node(node: Node, new_type: String) -> void:
	var parent = node.get_parent()
	var parent_of_node = parent.get_parent()
	
	if not ClassDB.class_exists(new_type): printerr("Requested type/class '" + new_type + "' does not exist!")
	
	var new_node: Node = ClassDB.instantiate(new_type)
	
	parent.replace_by(new_node, true)
	new_node.transform = parent.transform
	new_node.name = parent.name
	new_node.set_owner(main_scene)


func _delete_node(node: Node) -> void:
	var parent = node.get_parent()
	parent.remove_child(node)


func _set_owner_recursive(node: Node, owner: Node) -> void:
	node.set_owner(owner)
	for child in node.get_children():
		_set_owner_recursive(child, owner)


func _clear_owner_recursive(node: Node) -> void:
	node.set_owner(null)
	for child in node.get_children():
		_clear_owner_recursive(child)


func _is_node3d_wrapper(node: Node) -> bool:
	if node.get_class() != "Node3D":
		return false
	if node.get_parent() == null:
		return false
	if node.get_child_count() < 1:
		return false
	if node.get_script() != null:
		return false
	
	return true


func _first_node3d_descendant(root: Node) -> Node3D:
	for child in root.get_children():
		if child is Node3D:
			return child as Node3D
		
		var deeper := _first_node3d_descendant(child)
		if deeper != null:
			return deeper
	
	return null


func _bake_into_targets_and_hoist(wrapper: Node3D) -> void:
	var parent := wrapper.get_parent()
	if parent == null:
		return
	
	var children := wrapper.get_children()
	var bake_targets: Array = []
	
	for child in children:
		if child is Node3D:
			bake_targets.append(child)
		else:
			var first3d := _first_node3d_descendant(child)
			if first3d != null:
				bake_targets.append(first3d)
	
	for target in bake_targets:
		var element := target as Node3D
		target.transform = wrapper.transform * element.transform
	
	var insert_idx := parent.get_children().find(wrapper)
	for idx in range(children.size()):
		var child := children[idx]
		wrapper.remove_child(child)
		
		_clear_owner_recursive(child)
		
		parent.add_child(child)
		parent.move_child(child, insert_idx + idx)
		_set_owner_recursive(child, main_scene)

	parent.remove_child(wrapper)
	wrapper.free()


func _maintain_hierarchy(wrapper: Node3D) -> void:
	var parent := wrapper.get_parent()
	if parent == null:
		return
	
	var children := wrapper.get_children()
	
	var anchor: Node3D = null
	for child in children:
		if child is Node3D:
			anchor = child
			break
	
	if anchor == null:
		_bake_into_targets_and_hoist(wrapper)
		return
	
	var Tw := wrapper.transform
	var Ta := anchor.transform
	var Ta_inv := Ta.affine_inverse()
	
	anchor.transform = Tw * Ta
	
	for child in children:
		if child == anchor:
			continue
		if child is Node3D:
			var node: Node3D = child
			node.transform = Ta_inv * node.transform
		else:
			var first_node := _first_node3d_descendant(child)
			if first_node != null:
				first_node.transform = Ta_inv * first_node.transform
	
	var insert_idx := parent.get_children().find(wrapper)
	
	wrapper.remove_child(anchor)
	_clear_owner_recursive(anchor)
	parent.add_child(anchor)
	parent.move_child(anchor, insert_idx)
	_set_owner_recursive(anchor, main_scene)

	for child in children:
		if child == anchor:
			continue
		if child.get_parent() == wrapper:
			wrapper.remove_child(child)
		
		_clear_owner_recursive(child)
		anchor.add_child(child)
		_set_owner_recursive(child, main_scene)

	parent.remove_child(wrapper)
	wrapper.free()


func _prune_plain_node3d_wrappers_once(node: Node) -> int:
	var removed := 0
	var children := node.get_children()
	
	for child in children:
		removed += _prune_plain_node3d_wrappers_once(child)
	
	if _is_node3d_wrapper(node):
		_maintain_hierarchy(node as Node3D)
		removed += 1
	
	return removed


func _prune_node3d_wrappers(root: Node) -> void:
	var guard := 64
	
	while guard > 0:
		var removed := _prune_plain_node3d_wrappers_once(root)
		if removed <= 0:
			break
		
		guard -= 1
