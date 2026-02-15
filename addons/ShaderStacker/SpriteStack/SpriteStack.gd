@tool
extends Node2D
class_name SpriteStack
## Sprite node that uses a sprite sheet to display a 3D-like object using the 2D layers of the sprite sheet.
##
## The sprite stack is rendered by drawing each layer of the spritesheet 
## with an offset based on the [member pitch] and [member yaw].

@export_category("Sprite Stack")

## Spritesheet containing every layers of the sprite stack.
@export var sprite_sheet: Texture2D = null :
	set(value):
		sprite_sheet = value
		if Engine.is_editor_hint():
			_generate_stacked_texture()

## Preview of the final stacked sprite generated for the editor disregarding the [member yaw].
@export_custom(PROPERTY_HINT_NONE,"",PROPERTY_USAGE_READ_ONLY + PROPERTY_USAGE_EDITOR) var sprite_preview: Texture2D = null

## Number of layers in the [member sprite_sheet].
@export var layers: int = 1:
	set(value):
		layers = value
		if Engine.is_editor_hint():
			_generate_stacked_texture()

## Base height offset of the sprite stack.
@export var z: int = 0

## Yaw of the sprite stack, in degrees.
@export_range(0, 360, 0.01, "radians_as_degrees") var yaw: float = 0.0

## Pitch of the sprite stack, affects the distance between layers.
@export_range(0, 16, 0.1, "suffix:px") var pitch: float = 1.0:
	set(value):
		pitch = value
		if Engine.is_editor_hint():
			_generate_stacked_texture()

## If [code]true[/code], the [member yaw] is unaffected by the camera's rotation.
@export var static_yaw: bool = false

## If [code]true[/code], the sprite stack will not be added to the z-sorting group.
@export var static_z: bool = false

func _ready():
	var viewport := get_viewport()
	var id: int = viewport.get_viewport_rid().get_id()
	if (not static_z):
		add_to_group("zsort{viewportRID}".format({ "viewportRID": id }))
	if Engine.is_editor_hint():
		_generate_stacked_texture()

func _process(_delta):
	queue_redraw()

func _draw():
	if not sprite_sheet:
		return
	var sheet_size := sprite_sheet.get_size()
	var layer_size: Vector2 = sheet_size / Vector2(1, layers)
	var base_rect := Rect2(Vector2.ZERO, layer_size)
	
	var cam := get_viewport().get_camera_2d()
	var cam_rot: float = cam.global_rotation if cam and not static_yaw and not Engine.is_editor_hint() else 0.0
	var squish: float = (cam.zoom.x / cam.zoom.y if cam else 1.0)
	
	var up_vector := Vector2(0, -pitch).rotated(yaw + cam_rot - global_rotation) * squish
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(2, 2)) # Double sized pixels because they look better
	for i in range(1, layers + 1):
		draw_texture_rect_region(
				sprite_sheet,
				Rect2(Vector2.ZERO - (base_rect.size / 2) + i * up_vector - z * up_vector,
						base_rect.size),
				Rect2(Vector2(0, sheet_size.y - i * layer_size.y),
						layer_size))

## Generates a flattened preview texture of the sprite stack for the editor.
func _generate_stacked_texture() -> void:
	if not sprite_sheet:
		sprite_preview = null
		return

	var sheet_image: Image = sprite_sheet.get_image()
	if not sheet_image:
		sprite_preview = null
		return

	var sheet_size: Vector2i = sheet_image.get_size()
	if layers <= 0:
		sprite_preview = null
		return
	var layer_size: Vector2i = sheet_size / Vector2i(1, layers)
	
	var output_width: int = layer_size.x
	var output_height: int = layer_size.y + int(abs(layers - 1) * pitch)
	
	if output_width <= 0 or output_height <= 0:
		sprite_preview = null
		return

	var output_image: Image = Image.create_empty(output_width, output_height, false, sheet_image.get_format())
	
	if pitch >= 0:
		for i in range(layers - 1, -1, -1):
			var src_rect := Rect2i(Vector2i(0, i * layer_size.y), layer_size)
			var dst_pos := Vector2i(0, i * pitch)
			output_image.blend_rect(sheet_image, src_rect, dst_pos)
	else:
		for i in range(layers - 1, -1, -1):
			var src_rect := Rect2i(Vector2i(0, i * layer_size.y), layer_size)
			var dst_pos := Vector2i(0, (layers - 1 - i) * -pitch)
			output_image.blend_rect(sheet_image, src_rect, dst_pos)
		
	sprite_preview = ImageTexture.create_from_image(output_image)
