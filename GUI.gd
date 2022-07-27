extends Control

var animation_name
var loaded = -1
var texture_loader
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Loader.images and loaded >= 0:
		$MainCenterContainer/ActiveContainer.visible = false
		$MainCenterContainer/LoadingContainer.visible = true
		Loader.images.create_frames_timed(Loader.image_files, animation_name, texture_loader, 50.0)
		
		loaded = Loader.images.frames.get_frame_count(animation_name)
		#$LoadingSprite2D.texture = Loader.images.frames.get_frame(animation_name, loaded)
		var progress = 100.0 * float(loaded) / float(Loader.image_files.size())
		$MainCenterContainer/LoadingContainer/ProgressBar.value = progress
		print("progress", progress)
		if loaded == Loader.image_files.size():
			loaded = -1
			images_finished_loading()
			if not ResourceLoader.exists(Loader.images.save_path):
				var file_format = "user://framedata_%s_%d.res"
				var save_path = file_format % [animation_name, Loader.image_files.size()]
				Loader.images.save_frames(save_path)
			
		
func images_finished_loading() -> void:
	$MainCenterContainer/ActiveContainer.visible = true
	$MainCenterContainer/LoadingContainer.visible = false
	$MainCenterContainer/ActiveContainer/ButtonContainer/CreateImagePackButton.disabled = true
	$MainCenterContainer/ActiveContainer/ButtonContainer/LoadPackButton.disabled = true
	$MainCenterContainer/ActiveContainer/ButtonContainer/LoadSequenceButton.disabled = false
	$MainCenterContainer/ActiveContainer/ButtonContainer/StartButton.disabled = false

		
func _on_create_image_pack_button_pressed():
	$ImagesFileDialog.popup_centered()
	#$ImagesFileDialog.invalidate()
	#$MainCenterContainer/ActiveContainer.visible = false
	
#	$MainCenterContainer/LoadingContainer.visible = true
	


func _on_images_file_dialog_dir_selected(dir):
#	$MainCenterContainer/LoadingContainer.visible = true
	Loader.image_files = Loader.get_dir_contents(dir)[0]
	var last_folder = dir.rsplit("/", false, 1)[1]
	last_folder = last_folder.validate_node_name().to_lower() # remove junk and lower
	$AnimationNamePopup.set_default_name(last_folder)
	$AnimationNamePopup.popup_centered()
	


func _on_name_button_pressed():
	$AnimationNamePopup.hide()
	animation_name = $AnimationNamePopup/NamePanel/NameVBoxContainer/NameTextEdit.text
	loaded = 0
	texture_loader = func(image_file):
		return Loader.load_texture(image_file)
	$MainCenterContainer/ActiveContainer.visible = false
	$MainCenterContainer/LoadingContainer.visible = true


func _on_load_sequence_button_pressed():
	$SequenceFileDialog.popup_centered()


func _on_load_pack_button_pressed():
	$PackFileDialog.popup_centered()


func _on_sequence_file_dialog_file_selected(path : String):
	var sequence = Loader.load_sequence_file(path)
	var sequence_name = path.get_file().get_basename()
	if sequence_name != "" and Loader.images:
		Loader.images.add_sequence(sequence_name, sequence)
		Loader.images.change_animation(sequence_name) # switch to loaded sequence


func _on_start_button_pressed() -> void:
	get_tree().change_scene("res://speed_test.tscn")


func _on_pack_file_dialog_file_selected(path : String) -> void:
	# load 
	if path != "":
		Loader.images.load_image_pack(path)
		print("Loaded ", path)
		images_finished_loading()
