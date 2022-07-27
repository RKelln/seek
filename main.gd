extends Node2D

# 'user://test_godot4_framedata_plant_stills_hd_1994.res'

var default_image_pack = 'user://framedata_laura_164.res'
var images

# Called when the node enters the scene tree for the first time.
func _ready():
	images = Loader.images
	if images.get_total_frame_count() > 0:
		add_child(images)
		#images.play(images.frames.get_animation_names()[0])
	else:
		load_defaults()


func load_defaults():
	if ResourceLoader.exists(default_image_pack):
		images.load_image_pack(default_image_pack)
		add_child(images)
