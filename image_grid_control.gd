extends Control

var images

# Called when the node enters the scene tree for the first time.
func _ready():
	images = Loader.images
	if images.get_total_frame_count() <= 0:
		images = Loader.load_defaults()
	images.visible = false
	images.gui = false
	add_child(images)

	await get_tree().create_timer(2).timeout
	%ImageGrid.set_images(images.get_frames())
	
	

