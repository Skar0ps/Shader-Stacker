extends Camera2D
class_name StackCamera
## Camera that manages Z-sorting for [SpriteStack] and [Reset2D] nodes.
##
## This camera automatically sorts nodes in the "zsort" group based on their 
## global position relative to the camera's rotation and their height [member SpriteStack.z] property.

## The name of the group used for z-sorting nodes within this camera's viewport.
var _sort_group_name: String

func _ready() -> void:
	var id: int = get_viewport().get_viewport_rid().get_id()
	_sort_group_name = "zsort{viewportRID}".format({ "viewportRID": id })
	ignore_rotation = false

func _process(_delta: float) -> void:
	if not enabled:
		return
	
	_update_render_order()

func _update_render_order() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group(_sort_group_name)
	nodes.sort_custom(_sort_by_vertical_position)
	
	var z_index_offset: int = -nodes.size() / 2
	
	for i in nodes.size():
		var node = nodes[i]
		if node is Node2D:
			node.z_index = z_index_offset + i
			node.z_as_relative = false

func _sort_by_vertical_position(a: Node, b: Node) -> bool:
	var height_a: int = 0 if a.get("z") == null else a.z
	var height_b: int = 0 if b.get("z") == null else b.z
	
	if height_a != height_b:
		return height_a > height_b
	
	var screen_y_a: float = 0.0 if a.get("global_position") == null else a.global_position.rotated(-global_rotation).y
	var screen_y_b: float = 0.0 if b.get("global_position") == null else b.global_position.rotated(-global_rotation).y
	
	return screen_y_a < screen_y_b
