extends Node2D

# 'user://test_godot4_framedata_plant_stills_hd_1994.res'
const Images = preload("res://images.tscn")

var default_image_pack = 'user://framedata_laura_164.res'
var images : Node
var help : Window
var paused := false

var active_layers : Array[int] = Array()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	images = preload("res://images.tscn").instantiate()
	if Loader.images.get_total_frame_count() <= 0:
		images.set_image_frames(Loader.load_defaults())
	else:
		images.set_image_frames(Loader.images)
	$Stage.add_child(images)
	images.active = true
	
	# create other layers
#	var num_layers = 3
#	for i in range(num_layers):
#		var c = preload("res://images.tscn").instantiate()
#		if Loader.images.get_total_frame_count() <= 0:
#			c.set_image_frames(Loader.load_defaults())
#		else:
#			c.set_image_frames(Loader.images)
#		$Stage.add_child(c)
#		c.active = false
	
	images = $Stage.get_child(-1)
	images.active = true
	
	help = %HelpPopup
	help.close_requested.connect(resume)
	
	%SavePackFileDialog.file_selected.connect(func(path : String): Loader.images.save(path))
	
	%ImageGridControl.set_images(images.get_textures(), 5, images.get_current_frame_index())

	#Controller.mode = Controller.Mode.SKIP  # uncomment to turn on controller


func _input(event : InputEvent) -> void:
	if event.is_action_released('help'):
		# FIXME: popup has no variable that works for determining if it is active!
		#        This is because the esc key and clicking outside the popup by default close it
		# FIXME: help is a regular window, not popup but is marked as a popup, and needs its own script
		#        there must be a better way this is insanity. Tis resume never gets called, see the helpwindow script instead
		if paused:
			resume()
			help.hide()
		else:
			pause() 
			help.popup()
		
	if event.is_action_released("image_grid"):
		if %ImageGridControl.visible:
			%ImageGridControl.visible = false
			# update sequence with changes from image grid
			var seq_name = images.get_sequence_name()
			var seq = %ImageGridControl.get_sequence(seq_name)
			var cur_seq = images.get_sequence(seq_name)
			# if equivalent size
			if seq.size() == cur_seq.size():
				if seq != cur_seq: # if not already equal then update
					images.update_sequence(seq_name, seq)
			else:
				printt("Error: image grid sequence and images sequence don't match", seq, images.get_sequence())
		else:
			pause()
			%ImageGridControl.visible = true
			%ImageGridControl.set_center(images.get_current_frame_index())

	if event.is_action_released("duplicate_layer"):
		if $Stage.get_child_count() >= 3: return
		printt("duplicating layer")
		var orig = $Stage.get_child(get_active_layer()) # TODO: get active
		#var n = orig.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS)
#		var n = orig.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS )
		var n = Images.instantiate()
		n.set_image_frames(orig.get_image_frames().duplicate())
		orig.active = false
		$Stage.add_child(n)
		n.active = true
		
	if event.is_action_released("fullscreen_toggle"):
		if get_tree().get_root().mode == Window.MODE_FULLSCREEN:
			get_tree().get_root().mode = Window.MODE_WINDOWED
		else:
			get_tree().get_root().mode = Window.MODE_FULLSCREEN


	if event.is_action_released("save"):
		%SavePackFileDialog.popup()


	# number key: change active layer
	# set active layers by checking all keys that are pressed
	if event is InputEventKey:
		if event.keycode >= KEY_KP_1 and event.keycode <= KEY_KP_3:
			var layer = event.keycode - KEY_KP_1
			# on press add to active
			if event.pressed and event.echo == false:
				#printt("numpad", layer, $Stage.get_child_count(), event)
				if layer <= $Stage.get_child_count():
					var n = $Stage.get_child(layer)
					if n:
						prints("activate", layer)
						n.active = true
						active_layers.append(layer)
	
			# release: anything not in active_layers gets turned off
			# once all layer eys are release
			if not event.pressed: 
				if Input.is_key_pressed(KEY_KP_1) or Input.is_key_pressed(KEY_KP_2) or Input.is_key_pressed(KEY_KP_3):
					return
				# release active layers
				for i in $Stage.get_child_count():
					if not active_layers.has(i):
						prints("turn off layer", i)
						$Stage.get_child(i).active = false
				active_layers.clear()


func change_layer(layer_num : int) -> void:
	printt("change_layer", layer_num)
	if layer_num <= $Stage.get_child_count(): 
		for n in $Stage.get_children():
			n.active = false
		$Stage.get_child(layer_num - 1).active = true


func pause() -> void:
	images.pause()
	paused = true
	
	
func resume() -> void:
	images.resume()
	paused = false
	

func get_active_layer() -> int:
	for c in $Stage.get_children():
		if c.active:
			return c.get_index()
	print("Failed to find active layer")
	return 0


func _on_save_pack_file_dialog_file_selected(path):
	Loader.images.save(path)
