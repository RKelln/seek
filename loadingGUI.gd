extends Control

var create_pack_name : String
var save_pack_name : String
var loaded = -1
var texture_loader


var file_format = "framedata_%s_%d.res"
var default_save_path = "user://"

var _image_files : PackedStringArray
var active_image_pack : ImageFrames # currently loading/selected image pack
var loaded_image_packs : Array[ImageFrames]

var InfoPanel := preload("res://pack_info_panel.tscn")

var popup_size_ratio := 0.7


func _ready() -> void:
	# signals:
	%CreateImagePackButton.pressed.connect(func (): $ImagesFileDialog.popup_centered_ratio(popup_size_ratio) )
	$ImagesFileDialog.dir_selected.connect(_on_images_file_dialog_dir_selected)
	
	%LoadPackButton.pressed.connect(func (): $PackFileDialog.popup_centered_ratio(popup_size_ratio) )
	$PackFileDialog.file_selected.connect(_on_pack_file_dialog_file_selected)

	%SaveAsButton.pressed.connect(_on_save_as_button_pressed)
	$SavePackFileDialog.file_selected.connect(_on_save_pack_file_dialog_file_selected)

	%LoadSequenceButton.pressed.connect(func (): $SequenceFileDialog.popup_centered_ratio(popup_size_ratio) )
	$SequenceFileDialog.file_selected.connect(_on_sequence_file_dialog_file_selected)

	%LoadTagsButton.pressed.connect(func (): $TagsFileDialog.popup_centered_ratio(popup_size_ratio) )
	$TagsFileDialog.file_selected.connect(_on_tags_file_dialog_file_selected)
	
	%LoadNeighboursButton.pressed.connect(func (): $NeighboursFileDialog.popup_centered_ratio(popup_size_ratio) )
	$NeighboursFileDialog.file_selected.connect(_on_neighbours_file_dialog_file_selected)

	%StartButton.pressed.connect(_on_start_button_pressed)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if active_image_pack and loaded >= 0:
		$ActiveContainer.visible = false
		$LoadingContainer.visible = true
		$LoadingSprite2D.visible = true
		$LoadingSprite2D.texture = active_image_pack.create_frames_timed(_image_files, create_pack_name, texture_loader, 50.0)
		
		loaded = active_image_pack.get_frame_count(create_pack_name)
		var progress = 100.0 * float(loaded) / float(_image_files.size())
		$LoadingContainer/ProgressBar.value = progress
		if loaded == _image_files.size():
			loaded = -1
			_image_files.clear()
			images_finished_loading()
			var save_path = file_format % [create_pack_name, active_image_pack.get_base_frame_count()]
			$SavePackFileDialog.current_file = save_path
			$SavePackFileDialog.popup_centered_ratio(popup_size_ratio)


func images_finished_loading() -> void:
	$LoadingSprite2D.visible = false
	$ActiveContainer.visible = true
	$LoadingContainer.visible = false
	#$MainCenterContainer/ActiveContainer/ButtonContainer/CreateImagePackButton.disabled = true
	#$MainCenterContainer/ActiveContainer/ButtonContainer/LoadPackButton.disabled = true
	%LoadSequenceButton.disabled = false
	%LoadTagsButton.disabled = false
	%LoadNeighboursButton.disabled = false
	%StartButton.disabled = false
	%SaveAsButton.disabled = false
	prints("Video texture mem:", Loader.formatBytes(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))


func create_info_panel(save_path : String, info : Dictionary) -> void:
	var panel = InfoPanel.instantiate()
	info['save_path'] = save_path
	panel.set_values(info)
	%InfoContainer.add_child(panel)


func combine_image_packs(packs : Array) -> ImageFrames:
	if packs.size() == 1:
		return packs[0]
	
	var combined :=  ImageFrames.combine_image_packs(packs)
		
	# clear out loaded packs and info
	for n in %InfoContainer.get_children():
		%InfoContainer.remove_child(n)
		n.queue_free()
	packs.clear()
	
	return combined

func _on_create_image_pack_button_pressed():
	$ImagesFileDialog.popup_centered_ratio(popup_size_ratio)


func _on_images_file_dialog_dir_selected(dir : String):
#	$MainCenterContainer/LoadingContainer.visible = true
	_image_files = Loader.get_dir_contents(dir)[0]
	_image_files.sort()
	var last_folder = dir.rsplit("/", false, 1)[1]
	last_folder = ImageFrames.normalize_name(last_folder)
	$AnimationNamePopup.set_default_name(last_folder)
	$AnimationNamePopup.popup_centered_ratio(popup_size_ratio)
	
	#create_pack_name = await %NamePanel.response_submitted
	var values = await %NamePanel.response_submitted
	create_pack_name = ImageFrames.normalize_name(values[0])
	var fps = values[1]
	$AnimationNamePopup.visible = false
	if create_pack_name != "":
		$ActiveContainer.visible = false
		$LoadingContainer.visible = true
		
		# setup for loading code in _process():
		active_image_pack = ImageFrames.new()
		active_image_pack.pack_name = create_pack_name
		active_image_pack.fps = fps
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
	$SequenceFileDialog.popup_centered_ratio(popup_size_ratio)


func _on_load_pack_button_pressed():
	$PackFileDialog.popup_centered_ratio(popup_size_ratio)


func _on_pack_file_dialog_file_selected(path):
	# load 
	if path != "":
		active_image_pack = ImageFrames.load_image_pack(path)
		loaded_image_packs.append(active_image_pack)
		
#		if Loader.images.get_total_frame_count() > 0:
#			Loader.images.add_frames(imageFrames)
#		else:
#			Loader.images = imageFrames
#			print("Loaded ", path)
		
		create_info_panel(path, active_image_pack.info())
		images_finished_loading()


func _on_sequence_file_dialog_file_selected(path : String):
	# FIXME: active image pack
	if active_image_pack:
		var seq : Sequence = Loader.load_sequence_file(path)
		if seq and seq.size() > 0:
			var seq_name = ImageFrames.normalize_name(path.get_file().get_basename())
			active_image_pack.add_sequence(seq_name, seq)
			printt(seq_name, seq, active_image_pack.get_animation_names())
			# TODO: hook up info panel


func _on_tags_file_dialog_file_selected(path : String):
	if active_image_pack:
		var tag_data = Loader.load_tag_file(path)
		if tag_data:
			var tags : Dictionary = tag_data[0]
			var flags : PackedInt64Array = tag_data[1]
			var mapping : TagFlagKeyMap = tag_data[2]
			active_image_pack.tags = tags
			active_image_pack.flags = flags
			active_image_pack.mapping = mapping


func _on_neighbours_file_dialog_file_selected(path : String):
	if active_image_pack:
		var neighbours_data : Array[Sequence] = Loader.load_neighbours_file(path)
		if neighbours_data:
			active_image_pack.neighbours = neighbours_data


func _on_start_button_pressed() -> void:
	# combine packs
	if loaded_image_packs.size() > 1:
		Loader.images = combine_image_packs(loaded_image_packs)
	else:
		Loader.images = active_image_pack
	get_tree().change_scene_to_file("res://seek.tscn")


func _on_save_as_button_pressed():
	$AnimationNamePopup.set_default_name(ImageFrames.normalize_name(save_pack_name))
	$AnimationNamePopup.popup_centered()
	var values = await %NamePanel.response_submitted
	save_pack_name = values[0]
	var fps = values[1]
	active_image_pack = combine_image_packs(loaded_image_packs)
	active_image_pack.pack_name = ImageFrames.normalize_name(save_pack_name)
	active_image_pack.fps = fps
	$SavePackFileDialog.current_file = save_pack_name
	$SavePackFileDialog.popup_centered_ratio(popup_size_ratio)


func _on_save_pack_file_dialog_file_selected(path):
	if path != "":
		$SavePackFileDialog.visible = false
		active_image_pack.save(path)
		create_info_panel(path, active_image_pack.info())
		loaded_image_packs.append(active_image_pack)
	
