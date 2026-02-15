extends Node2D
class_name Reset2D
## Node that resets its transform properties to align with a [StackCamera].
##
## This node ensures that its children are rendered upright and correctly sorted 
## within a sprite stacking environment by counteracting camera rotation and zoom.

@export_category("Reset2D")
## Base height offset of the node for z-sorting.
@export var z: int = 0
## If [code]true[/code], the node's position will be offset by its [member z] value relative to the camera's rotation.
@export var reset_position: bool = true
## If [code]true[/code], the node's rotation will be synced with the camera's rotation.
@export var reset_rotation: bool = true
## If [code]true[/code], the node's vertical scale will be adjusted based on the camera's zoom to maintain visual consistency.
@export var reset_scale: bool = true

func _ready():
	var id: int = get_viewport().get_viewport_rid().get_id()
	add_to_group("zsort{viewportRID}".format({ "viewportRID": id }))

func _process(delta):
	var cam := get_viewport().get_camera_2d()
	var cam_rot: float = (cam.global_rotation if cam else 0.0)
	var squish: float = 1.0 / (cam.zoom.y if cam else 1.0)
	
	var up_vector := Vector2(0, -1).rotated(cam_rot) * squish
	
	if reset_scale:
		self.scale.y = squish
	if reset_rotation:
		self.rotation = cam_rot
	if reset_position:
		self.position = up_vector * z
