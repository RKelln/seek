extends Node2D

@export_node_path("Label") var _frameNode
@export_node_path("Label") var _totalFramesNode
@export_node_path("Label") var _actualFrameNode
@export_node_path("Label") var _runningTotalFramesNode

@export var active : bool = false:
	get:
		return active
	set(on):
		if active and on: return
		if not active and not on: return
		prints(_index, "activate images:", on)
		active = on
		if cur_img:
			cur_img.active = on

@export var pack_name : String = "":
	get:
		if cur_img:
			return cur_img.pack_name
		return pack_name
	set(value):
		pack_name = value
		if cur_img:
			cur_img.pack_name = value

var gui := false

# transitions
var transition := true
var transition_out_tween : Tween
var transition_in_tween : Tween
var transition_cutoff := 0.042 # 24 fps = 0.042
var transition_percent := 0.1 # scale transition time such that 0.1 = 10% transition, 90% hold on full image
var _prevTexture : Texture2D
var _next_transition_delay : SceneTreeTimer

# alpha
var opacity_speed := 0.6

# beat match
var last_beat_ms := 0.0
var beats_ms : PackedFloat32Array
var beat_average := 0.0

const AnimatedImage = preload("res://AnimatedImage.gd")
var cur_img : AnimatedImage
var prev_img : Sprite2D

var controller : CustomController

var _index : int

func _init_node(nodeOrPath, defaultPath) -> Node:
	if nodeOrPath is Node:
		return nodeOrPath
	elif nodeOrPath is NodePath:
		return get_node(nodeOrPath)
	else:
		return get_parent().find_child(defaultPath)


# Called when the node enters the scene tree for the first time.
func _ready():
	if gui:
		_frameNode = %Frame
		_totalFramesNode = %TotalFrames
		_actualFrameNode = %ActualFrame
		_runningTotalFramesNode = %RunningTotal
	
	cur_img = $CanvasGroup/AnimatedSprite2D
	prev_img = $CanvasGroup/PrevImage
	assert(cur_img != null)
	assert(prev_img != null)
	
	# signals
	cur_img.real_frame_changed.connect(_on_real_frame_changed)
	
	# init pack name if not already set
	if pack_name != "":
		if cur_img.pack_name != "":
			if pack_name != cur_img.pack_name:
				printt("images.gd and AnimatedSrpite2D pack_names differ", pack_name, cur_img.pack_name)
				pack_name = cur_img.pack_name
		else:
			cur_img.pack_name = pack_name
	
	_index = get_index()
	cur_img._index = _index
	
	# midi and movie maker do not work together
	if not OS.has_feature("movie"):
		controller = preload("res://midi_controller.gd").new()
		controller.mode = CustomController.Mode.TEST
		add_child(controller)
	

func _process(delta : float) -> void:
	if active:
		# this interacts awkwardly with pressed action check in _unhandled_input
		# but is the simplest way to allow for the same control to do step-by-step
		# (from knob) and continuously held input (from keyboard)
		if Input.is_action_pressed("increase_opacity") and modulate.a < 1.0:
			change_opacity(delta * opacity_speed)
		if Input.is_action_pressed("decrease_opacity") and modulate.a > 0:
			change_opacity(-delta * opacity_speed)

		# camera movement
		$CanvasGroup/Camera2D.zoom.x = $CanvasGroup/Camera2D/Zoom.process(delta)
		$CanvasGroup/Camera2D.zoom.y = $CanvasGroup/Camera2D.zoom.x
		$CanvasGroup/Camera2D.position.x = $CanvasGroup/Camera2D/TranslateX.process(delta)
		$CanvasGroup/Camera2D.position.x = $CanvasGroup/Camera2D/TranslateY.process(delta)
		

func _unhandled_input(event : InputEvent) -> void:
	if not active: return
	if event is InputEventMouseMotion: return
		
	if event is InputEventTargetedAction:
		# note: do not check for pressed, 
		#       as these events may have strength
		#       that changes throughout a "press"
		if valid_target(event.target):
			prints("InputEventTargetedAction", event.as_text())
			match event.action:
				"set_opacity":
					set_opacity(event.strength, event.target)
				"set_transition_duration":
					set_transition_duration(event.strength, event.target)
		return
	
	if event.is_action_pressed("beat_match"):
		beat_match()
	elif event.is_action_pressed("next_animation"):
		change_animation(1)
	elif event.is_action_pressed("fade_less"):
		change_transition_duration(-0.05)
	elif event.is_action_pressed("fade_more"):
		change_transition_duration(0.05)
	elif event.is_action_pressed("increase_opacity") and modulate.a < 1.0:
		change_opacity(0.1 * opacity_speed)
	elif event.is_action_pressed("decrease_opacity") and modulate.a > 0:
		change_opacity(-0.1 * opacity_speed)
		
	# handle switching packs using keys
	if event is InputEventKey:
		if not event.pressed: # releaased
			if event.keycode >= KEY_0 and event.keycode <= KEY_9:
				var anims : PackedStringArray = get_valid_animation_names()
				var count := anims.size()
				var selected_anim : int = event.keycode - KEY_1
				# KEY_0 ihas lowest keycode but is rightmost on keyboard
				if event.keycode == KEY_0:
					selected_anim = 10
				elif event.shift_pressed:
					selected_anim += 10
				if selected_anim >= 0 and selected_anim < count:
					#printt(_index, "input", event.keycode, selected_anim)
					if get_sequence_name() != anims[selected_anim]:
						change_animation()
						cur_img.change_animation(anims[selected_anim])
		return

# called eery process from the movement_tween that does a sin-like movement
func _update_movement(value : float) -> void:
	printt("_update_movement", value)


func valid_target(index : int = -1) -> bool:
	if index < 0 and not active: return false
	if index >= 0 and index != _index : return false
	return true


func change_pause(layer : int = -1) -> void:
	if not valid_target(layer): return
	pause()


func change_animation(_dir : int = 0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	#printt(_index, "images.change_animation_relative", _dir)
	if transition:
		prev_img.visible = false
		_prevTexture = null
		if transition_out_tween:
			transition_out_tween.kill()
		if transition_in_tween:
			transition_in_tween.kill()
			cur_img.modulate.a = 1.0


func change_opacity(amount : float, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	printt(_index, "change_opacity", amount)
	modulate.a = clampf(modulate.a + amount, 0.0, 1.0)


func set_opacity(amount : float, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	printt(_index, "set_opacity", amount)
	modulate.a = clampf(amount, 0.0, 1.0)


func change_transition_duration(percent_change : float, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	#transition_percent = smoothstep(0, 1.0, transition_percent + percent_change)
	transition_percent = clampf(transition_percent + percent_change, 0.0, 1.0)
	printt(_index, "change_transition_duration", percent_change, transition_percent)


func set_transition_duration(duration : float, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	transition_percent = clampf(duration, 0.0, 1.0)
	printt(_index, "set_transition_duration", transition_percent)


func set_image_frames(iframes : ImageFrames) -> void:
	$CanvasGroup/AnimatedSprite2D.sprite_frames = iframes
 

func _on_real_frame_changed( frame : int) -> void:
	#printt("_on_real_frame_changed", frame, get_current_frame_index(), cur_img, prev_img)
	
	# update GUI
	if gui:
		_frameNode.text = str(cur_img.frame)
		if cur_img.animation == cur_img.custom_animation:
			_actualFrameNode.text = str(cur_img.current_sequence[cur_img.frame])
		else:
			_actualFrameNode.text = str(cur_img.frame)
		_runningTotalFramesNode.text = str( _runningTotalFramesNode.text.to_int() + 1)
		_totalFramesNode.text = str(cur_img.frame_counts[cur_img.animation])
	
	# update crossfade
	# https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult
	#$CrossfadeImage.material.set_shader_param("startTime", Time.get_ticks_msec() / 1000.0)
	#$CrossfadeImage.material.set_shader_param("duration", speed_scale / fps)
	#$CrossfadeImage.material.set_shader_param("prevTex", $CrossfadeImage.material.get_shader_param("curTex"))
	#$CrossfadeImage.material.set_shader_param("curTex", frames.get_frame(animation, frame))

	# FIXME: bug with modulate and tweens causing flashing!?
	if transition and modulate.a == 1.0:
		assert(cur_img != null)
		assert(prev_img != null)
	
		if _prevTexture != null:
			prev_img.texture = _prevTexture
		else:
			prev_img.texture = cur_img.get_current_frame()
		_prevTexture = cur_img.get_current_frame()
		if prev_img.texture != null:
			var duration = cur_img.get_frame_duration()
			#printt("frame change", cur_img.frame, duration)
			
			if duration > transition_cutoff:
				prev_img.visible = true
				# copy scale and offset
				# (luckily this works because this signal seems to be processed before the AnimatedSprite is updated, phew)
				if cur_img.stretch:
					prev_img.scale = cur_img.scale
					prev_img.offset = cur_img.offset
				if transition_out_tween:
					transition_out_tween.kill()
				transition_out_tween = prev_img.create_tween()
				# HACK: when duration is low then start more transparent
				var from = clampf(duration * transition_percent * 2.0, 0.5, 1.0) 
				var delay = (1.0 - transition_percent) * duration
				var t = transition_out_tween.tween_property(prev_img, "modulate:a", 0.0, duration * transition_percent).from(from)
				if delay > 0:
					prev_img.modulate.a = 1.0
					t.set_delay(delay)

				#printt("new transition", self, transition_out_tween, duration, from)
				# if different size then fade in the new image
				if prev_img.get_rect().size != cur_img.get_rect().size:
					#printt("not same size", prev_img.get_rect(), cur_img.get_rect())
					if transition_in_tween:
						transition_in_tween.kill()
					transition_in_tween = cur_img.create_tween()
					t = transition_in_tween.tween_property(cur_img, "modulate:a", 1.0, duration * transition_percent).from(0.0)
					if delay > 0:
						cur_img.modulate.a = 0
						t.set_delay(delay)
				elif cur_img.modulate.a != 1:
					cur_img.modulate.a = 1.0
			else:
				prev_img.visible = false


#func load_sequence(file_path : String):
#	var sequence = Loader.load_sequence_file(file_path)
#	var sequence_name = file_path.get_file().get_basename()
#	if sequence_name != "":
#		cur_img.add_sequence(sequence_name, sequence)
#		cur_img.change_animation(sequence_name) # switch to loaded sequence


func get_total_frame_count() -> int:
	if cur_img == null or cur_img.sprite_frames == null: return 0
	
	var count := 0
	for anim in cur_img.sprite_frames.get_animation_names():
		count += cur_img.sprite_frames.get_frame_count(anim)
	return count


func get_frame_count(anim_name : String = "") -> int:
	if cur_img == null or cur_img.sprite_frames == null: return 0
	
	if anim_name == "":
		anim_name = cur_img.animation
		
	return cur_img.sprite_frames.get_frame_count(anim_name)


func get_image_frames() -> ImageFrames:
	return cur_img.sprite_frames


func get_textures(anim_name : String = "") -> Array[Texture2D]:
	if anim_name == "":
		anim_name = cur_img.animation
		
	var sp = get_image_frames()
	var f : Array[Texture2D] = []
	for i in get_frame_count():
		# add sequence number to the frames meta data
		var t2d = sp.get_frame_texture(anim_name, i)
		t2d.set_meta(anim_name, i)
		f.append(t2d)
	return f


func get_current_frame_index() -> int:
	return cur_img.frame


func get_sequence_name() -> StringName:
	return cur_img.animation


func get_sequence(seq_name : String = "") -> PackedInt32Array:
	return cur_img.sprite_frames.get_sequence(seq_name)


func update_sequence(seq_name : String, sequence : PackedInt32Array) -> void:
	cur_img.pause()
	cur_img.animation = cur_img.sprite_frames.base_animation_name # switch away temporarily
	cur_img.sprite_frames.update_frames(seq_name, sequence)
	cur_img.change_animation(seq_name)
	restart()


func get_valid_animation_names() -> PackedStringArray:
	return cur_img.sprite_frames.get_valid_animation_names()


func info() -> Dictionary:
	return cur_img.info()


func pause():
	cur_img.pause()
	if transition_out_tween and transition_out_tween.is_valid() and transition_out_tween.is_running():
		transition_out_tween.pause()
	if transition_in_tween and transition_in_tween.is_valid() and transition_in_tween.is_running():
		transition_in_tween.pause()
	
	
func resume():
	cur_img.resume()
	if transition_out_tween and transition_out_tween.is_valid():
		transition_out_tween.play()
	if transition_in_tween and transition_in_tween.is_valid():
		transition_in_tween.play()

func restart():
	cur_img.pause()
	prev_img.visible = false
	if transition_out_tween and transition_out_tween.is_valid() and transition_out_tween.is_running():
		transition_out_tween.stop()
	if transition_in_tween and transition_in_tween.is_valid() and transition_in_tween.is_running():
		transition_in_tween.stop()
	cur_img.frame = 0
 

func set_timing(duration_ms : float):
	var dur_s = duration_ms / 1000.0
	cur_img.set_frame_duration(dur_s)
	if transition_out_tween and transition_out_tween.is_valid() and transition_out_tween.is_running():
		transition_out_tween.stop()
	if transition_in_tween and transition_in_tween.is_valid() and transition_in_tween.is_running():
		transition_in_tween.stop()
	prev_img.visible = false
	#cur_img.next_frame() # immediately advance to sync to beat
	
	# try to adjust for transition
	if dur_s > transition_cutoff:
		if _next_transition_delay and _next_transition_delay.time_left > 0:
			#printt(_index, "delay transition", dur_s / 2.0)
			_next_transition_delay.time_left = dur_s / 2.0
		else:
			_next_transition_delay = get_tree().create_timer(dur_s / 2.0)
			#printt(_index, "start delay", dur_s / 2.0)
			await _next_transition_delay.timeout
			#printt(_index, "offset transition")
			cur_img.next_frame()
	else:
		cur_img.next_frame() # immediately advance to sync to beat


func beat_match(layer : int = -1) -> void:
	if not valid_target(layer): return
	
	# just getting started
	if last_beat_ms == 0.0:
		beats_ms.clear()
		beat_average = 0.0
		last_beat_ms = Time.get_ticks_msec()
		return
	
	var now = Time.get_ticks_msec()
	var diff = now - last_beat_ms
	
	if diff < 100:
		return # disregard, something probably went wrong
	
	# after 10 seconds reset beat match
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
	
	printt(_index, "beat_match", diff, beats_ms)
	
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
		
		set_timing(beat_average)
