extends Control

var images

# Called when the node enters the scene tree for the first time.
func _ready():
	#test()
	pass
	
# run this when testing the scene individually for some default data
func test():
	images = Loader.images
	if images.get_total_frame_count() <= 0:
		images = Loader.load_defaults()
	images.visible = false
	images.gui = false
	add_child(images)

	await get_tree().create_timer(2).timeout
	%ImageGrid.set_images(images.get_textures())


func set_images(new_images : Array, grid_size : int = 0, center_idx : int = -1) -> void:
	%ImageGrid.set_images(new_images, grid_size, center_idx)


func set_center(index : int) -> void:
	%ImageGrid.center = index


func get_sequence(seq_name : StringName) -> PackedInt32Array:
	var seq := PackedInt32Array()
	for img in %ImageGrid.get_children():
		var meta = img.texture.get_meta(ImageFrames.animation_meta_key)
		if typeof(meta) == TYPE_INT:
			seq.append(meta)
		else:
			print("get_sequence(): Invalid meta data for sequence: ", seq_name)
			return PackedInt32Array()
	return seq
