extends Control

var create_pack_name : String
var save_pack_name : String
var loaded = -1
var texture_loader

var file_format = "user://framedata_%s_%d.res"

var _image_files : Array[String]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Loader.images and loaded >= 0:
		$ActiveContainer.visible = false
		$LoadingContainer.visible = true
		$LoadingSprite2D.visible = true
		$LoadingSprite2D.texture = Loader.images.create_frames_timed(_image_files, create_pack_name, texture_loader, 50.0)
		
		loaded = Loader.images.get_frame_count(create_pack_name)
		var progress = 100.0 * float(loaded) / float(_image_files.size())
		$LoadingContainer/ProgressBar.value = progress
		if loaded == _image_files.size():
			loaded = -1
			_image_files.clear()
			images_finished_loading()
			Loader.images.pack_name = create_pack_name
			var save_path = file_format % [create_pack_name, Loader.images.get_total_frame_count()]
			if not ResourceLoader.exists(save_path):
				Loader.images.save(save_path)
			else:
				$SavePackFileDialog.current_file = save_path
				$SavePackFileDialog.popup()
			create_info_panel(save_path, Loader.images.info())


func images_finished_loading() -> void:
	$LoadingSprite2D.visible = false
	$ActiveContainer.visible = true
	$LoadingContainer.visible = false
	#$MainCenterContainer/ActiveContainer/ButtonContainer/CreateImagePackButton.disabled = true
	#$MainCenterContainer/ActiveContainer/ButtonContainer/LoadPackButton.disabled = true
	#$MainCenterContainer/ActiveContainer/ButtonContainer/LoadSequenceButton.disabled = false
	%StartButton.disabled = false
	%SaveAsButton.disabled = false


func create_info_panel(save_path : String, info : Dictionary) -> void:
	var panel = preload("res://pack_info_panel.tscn").instantiate()
	info['save_path'] = save_path
	panel.set_values(info)
	%InfoContainer.add_child(panel)


func _on_create_image_pack_button_pressed():
	$ImagesFileDialog.popup()


func _on_images_file_dialog_dir_selected(dir):
#	$MainCenterContainer/LoadingContainer.visible = true
	_image_files = Loader.get_dir_contents(dir)[0]
	_image_files.sort()
	var last_folder = dir.rsplit("/", false, 1)[1]
	last_folder = last_folder.validate_node_name().to_lower() # remove junk and lower
	$AnimationNamePopup.set_default_name(last_folder)
	$AnimationNamePopup.popup_centered()
	
	create_pack_name = await %NamePanel.response_submitted
	$AnimationNamePopup.visible = false
	if create_pack_name != "":
		$ActiveContainer.visible = false
		$LoadingContainer.visible = true
		
		# setup for loading code in _process():
		loaded = 0
		texture_loader = func(image_file):
			# TODO: FIXME: have user set rescale size
			return Loader.load_texture(image_file, Vector2(1920, 1080))


#func _on_name_button_pressed(pack_name : String):
#	$AnimationNamePopup.hide()
#	#pack_name = %NameTextEdit.text
#
#	create_pack_name = pack_name
#	loaded = 0
#	texture_loader = func(image_file):
#		# TODO: FIXME: have user set rescale size
#		return Loader.load_texture(image_file, Vector2(1920, 1080))
#	$ActiveContainer.visible = false
#	$LoadingContainer.visible = true
	

func _on_load_sequence_button_pressed():
	$SequenceFileDialog.popup()


func _on_load_pack_button_pressed():
	$PackFileDialog.popup_centered()


func _on_pack_file_dialog_file_selected(path):
	# load 
	if path != "":
		var imageFrames : ImageFrames = ImageFrames.load_image_pack(path)
		if Loader.images.get_total_frame_count() > 0:
			Loader.images.add_frames(imageFrames)
		else:
			Loader.images = imageFrames
			print("Loaded ", path)
		
		prints("Video texture mem:", Loader.formatBytes(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))
		
		create_info_panel(path, imageFrames.info())
		images_finished_loading()


func _on_sequence_file_dialog_file_selected(path : String):
	Loader.images.load_sequence(path)
	

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://speed_test.tscn")


func _on_save_as_button_pressed():
	$AnimationNamePopup.set_default_name(save_pack_name)
	$AnimationNamePopup.popup_centered()
	save_pack_name = await %NamePanel.response_submitted
	Loader.images.pack_name = save_pack_name
	$SavePackFileDialog.current_file = save_pack_name
	$SavePackFileDialog.popup()


func _on_save_pack_file_dialog_file_selected(path):
	if path != "":
		$SavePackFileDialog.visible = false
		Loader.images.save(path)

