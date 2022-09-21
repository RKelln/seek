extends Node2D

# 'user://test_godot4_framedata_plant_stills_hd_1994.res'
const Images = preload("res://images.tscn")

var default_image_pack = 'user://framedata_laura_164.res'
var images : Node
var help : Window
var paused := false
var last_beat_ms := 0.0
var beats_ms : PackedFloat32Array
var beat_average := 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	images = preload("res://images.tscn").instantiate()
	if Loader.images.get_total_frame_count() <= 0:
		images.set_image_frames(Loader.load_defaults())
	else:
		images.set_image_frames(Loader.images)
	$Stage.add_child(images)
	
	help = %HelpPopup
	%ImageGridControl.set_images(images.get_textures(), 5, images.get_current_frame_index())


func _process(delta) -> void:
	if Input.is_action_just_pressed('beat_match'):
		handle_beat_match(delta)


func _input(event : InputEvent) -> void:
	if event.is_action_released('help'):
		# FIXME: popup has no variable that works for determining if it is active!
		#        This is because the esc key and clicking outside the popup by default close it
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
		var orig = $Stage.get_child(get_active_layer()) # TODO: get active
		#var n = orig.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS | DUPLICATE_SIGNALS)
#		var n = orig.duplicate(DUPLICATE_GROUPS | DUPLICATE_SCRIPTS )
		var n = Images.instantiate()
		n.set_image_frames(orig.get_image_frames().duplicate())
		orig.active = false
		add_child(n)
		n.active = true
		
	if event.is_action_released("fullscreen_toggle"):
		if get_tree().get_root().mode == Window.MODE_FULLSCREEN:
			get_tree().get_root().mode = Window.MODE_WINDOWED
		else:
			get_tree().get_root().mode = Window.MODE_FULLSCREEN


	if event.is_action_released("save"):
		%SavePackFileDialog.popup()


	# number key: change active layer
	if event is InputEventKey and event.pressed and event.echo == false and not event.shift_pressed:
		var count := $Stage.get_child_count()
		var selected := 0
		match event.physical_keycode:
			KEY_1:
				selected = 1
			KEY_2:
				selected = 2
			KEY_3:
				selected = 3
			KEY_4:
				selected = 4
			KEY_5:
				selected = 5
			KEY_6:
				selected = 6
			KEY_7:
				selected = 7
			KEY_8:
				selected = 8
			KEY_9:
				selected = 9
			KEY_0:
				selected = 10
		
		if selected > 0 and selected <= count:
			change_layer(selected)


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


func handle_beat_match(_delta : float) -> void:
	# just getting started
	if last_beat_ms == 0.0:
		beats_ms.clear()
		beat_average = 0.0
		last_beat_ms = Time.get_ticks_msec()
		return
		
	# after 10 seconds reset beat match
	var now = Time.get_ticks_msec()
	var diff = now - last_beat_ms
	if diff > 10000 or (beat_average > 0 and (diff > beat_average * 3.0 or diff < beat_average / 4.0)):
		print("clear the beat")
		beats_ms.clear()
		beat_average = 0.0
		
	last_beat_ms = now
	# add a new beat
	beats_ms.append(now)
	
	# remove old beats
	if beats_ms.size() > 6:
		beats_ms.remove_at(0)
	
	# find average delay between beats, toss 1 outlier
	if beats_ms.size() >= 3:
		var timings = PackedFloat32Array()
		var sum := 0.0 
		for i in beats_ms.size() - 1:
			var dt = beats_ms[i+1] - beats_ms[i]
			timings.append(dt)
			sum += dt
		beat_average = sum / timings.size()
		#printt("beats", beat_average, timings)
		
		# throw out worst
		timings.sort()
		if abs(timings[0] - beat_average) > abs(timings[-1] - beat_average):
			sum -= timings[0]
		else:
			sum -= timings[-1]
		beat_average = sum / (timings.size() - 1)
		#printt("beats no worst", beat_average)
		
		images.set_timing(beat_average)


func _on_save_pack_file_dialog_file_selected(path):
	Loader.images.save(path)
