extends Control

var animation_name
var loaded = -1
var texture_loader
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Loader.images and loaded >= 0:
		$MainCenterContainer/ActiveContainer.visible = false
		$MainCenterContainer/LoadingContainer.visible = true
		$LoadingSprite2D.visible = true
		$LoadingSprite2D.texture = Loader.images.load_images(Loader.image_files, animation_name, texture_loader, 50.0)
		
		loaded = Loader.images.get_frame_count(animation_name)
		var progress = 100.0 * float(loaded) / float(Loader.image_files.size())
		$MainCenterContainer/LoadingContainer/ProgressBar.value = progress
		if loaded == Loader.image_files.size():
			loaded = -1
			images_finished_loading()
			if not ResourceLoader.exists(Loader.images.get_save_path()):
				var file_format = "user://framedata_%s_%d.res"
				var save_path = file_format % [animation_name, Loader.image_files.size()]
				Loader.images.save_frames(save_path)
			
		
func images_finished_loading() -> void:
	$LoadingSprite2D.visible = false
	$MainCenterContainer/ActiveContainer.visible = true
	$MainCenterContainer/LoadingContainer.visible = false
	$MainCenterContainer/ActiveContainer/ButtonContainer/CreateImagePackButton.disabled = true
	$MainCenterContainer/ActiveContainer/ButtonContainer/LoadPackButton.disabled = true
	$MainCenterContainer/ActiveContainer/ButtonContainer/LoadSequenceButton.disabled = false
	$MainCenterContainer/ActiveContainer/ButtonContainer/StartButton.disabled = false

		
func _on_create_image_pack_button_pressed():
	$ImagesFileDialog.popup_centered()


func _on_images_file_dialog_dir_selected(dir):
#	$MainCenterContainer/LoadingContainer.visible = true
	Loader.image_files = Loader.get_dir_contents(dir)[0]
	Loader.image_files.sort()
	var last_folder = dir.rsplit("/", false, 1)[1]
	last_folder = last_folder.validate_node_name().to_lower() # remove junk and lower
	$AnimationNamePopup.set_default_name(last_folder)
	$AnimationNamePopup.popup_centered()


func _on_name_button_pressed():
	$AnimationNamePopup.hide()
	animation_name = $AnimationNamePopup/NamePanel/NameVBoxContainer/NameTextEdit.text
	loaded = 0
	texture_loader = func(image_file):
		# TODO: FIXME: have user set rescale size
		return Loader.load_texture(image_file, Vector2(1920, 1080))
	$MainCenterContainer/ActiveContainer.visible = false
	$MainCenterContainer/LoadingContainer.visible = true


func _on_load_sequence_button_pressed():
	$SequenceFileDialog.popup_centered()


func _on_load_pack_button_pressed():
	$PackFileDialog.popup_centered()


func _on_sequence_file_dialog_file_selected(path : String):
	Loader.images.load_sequence(path)
	

func _on_start_button_pressed() -> void:
	get_tree().change_scene("res://speed_test.tscn")


func _on_pack_file_dialog_file_selected(path : String) -> void:
	# load 
	if path != "":
		Loader.images.load_image_pack(path)
		print("Loaded ", path)
		images_finished_loading()
