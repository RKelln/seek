extends Node2D

@export_node_path(Label) var _frameNode
@export_node_path(Label) var _totalFramesNode
@export_node_path(Label) var _actualFrameNode
@export_node_path(Label) var _runningTotalFramesNode

@export var active : bool = true
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
var transition_percent := 1.0 # scale transition time such that 0.1 = 10% transition, 90% hold on full image
var _prevTexture : Texture2D
var _next_transition_delay : SceneTreeTimer

# alpha
var opacity_speed := 1.0

const AnimatedImage = preload("res://AnimatedImage.gd")
var cur_img : AnimatedImage
var prev_img : Sprite2D

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
	

func _process(delta : float) -> void:
	if active:
		if Input.is_action_pressed("increase_opacity") and modulate.a < 1.0:
			modulate.a = clampf(modulate.a + delta * opacity_speed, 0.0, 1.0)
		if Input.is_action_pressed("decrease_opacity") and modulate.a > 0:
			modulate.a = clampf(modulate.a - delta * opacity_speed, 0.0, 1.0)
		cur_img.handle_input()


func set_image_frames(iframes : ImageFrames) -> void:
	$CanvasGroup/AnimatedSprite2D.frames = iframes
 

func _on_real_frame_changed():
	#printt("_on_animated_sprite_2d_frame_changed", self, get_current_frame_index(), cur_img, prev_img)
	
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
	
	if transition:
		if _prevTexture != null:
			prev_img.texture = _prevTexture
		_prevTexture = cur_img.get_current_frame()
		if prev_img.texture != null:
			var duration = cur_img.get_frame_duration()
			#printt("frame change", cur_img.frame, duration)
			
			if duration > transition_cutoff:
				prev_img.visible = true
				# copy scale and offset
				# (luckily this works because this signal seems to be processed before the AnimatedSPite is updated, phew)
				if cur_img.stretch:
					prev_img.scale = cur_img.scale
					prev_img.offset = cur_img.offset
				if transition_out_tween:
					transition_out_tween.kill()
				transition_out_tween = create_tween()
				# HACK: when duration is low then start more transparent
				var from = clampf(duration * transition_percent * 2.0, 0.5, 1.0) 
				var delay = (1.0 - transition_percent) * duration
				if delay > 0:
					prev_img.modulate.a = 1.0
					transition_out_tween.tween_property(prev_img, "modulate:a", 0.0, duration * transition_percent).from(from).set_delay(delay)
				else:
					transition_out_tween.tween_property(prev_img, "modulate:a", 0.0, duration * transition_percent).from(from)
				#printt("new transition", self, transition_out_tween, duration, from)
				# TOD: if different size then fade in the new image for half the duration?
				if prev_img.get_rect().size != cur_img.get_rect().size:
					#printt("not same size", prev_img.get_rect(), cur_img.get_rect())
					if transition_in_tween:
						transition_in_tween.kill()
					transition_in_tween = create_tween()
					cur_img.modulate.a = 0
					transition_in_tween.tween_property(cur_img, "modulate:a", 1.0, duration * transition_percent).from(0.0).set_delay(delay)
				elif cur_img.modulate.a != 1:
					cur_img.modulate.a = 1
			else:
				prev_img.visible = false


func load_sequence(file_path : String):
	var sequence = Loader.load_sequence_file(file_path)
	var sequence_name = file_path.get_file().get_basename()
	if sequence_name != "":
		cur_img.add_sequence(sequence_name, sequence)
		cur_img.change_animation(sequence_name) # switch to loaded sequence


func get_total_frame_count() -> int:
	if cur_img == null or cur_img.frames == null: return 0
	
	var count := 0
	for anim in cur_img.frames.get_animation_names():
		count += cur_img.frames.get_frame_count(anim)
	return count


func get_frame_count(anim_name : String = "") -> int:
	if cur_img == null or cur_img.frames == null: return 0
	
	if anim_name == "":
		anim_name = cur_img.animation
		
	return cur_img.frames.get_frame_count(anim_name)


func get_image_frames() -> ImageFrames:
	return cur_img.frames


func get_textures(anim_name : String = "") -> Array[Texture2D]:
	if anim_name == "":
		anim_name = cur_img.animation
		
	var sp = get_image_frames()
	var f = Array()
	for i in get_frame_count():
		# add sequence number to the frames meta data
		var t2d = sp.get_frame(anim_name, i)
		t2d.set_meta(anim_name, i)
		f.append(t2d)
	return f


func get_current_frame_index() -> int:
	return cur_img.frame


func get_sequence_name() -> StringName:
	return cur_img.animation


func get_sequence(seq_name : String = "") -> PackedInt32Array:
	return cur_img.frames.get_sequence(seq_name)


func update_sequence(seq_name : String, sequence : PackedInt32Array) -> void:
	cur_img.pause()
	cur_img.animation = cur_img.frames.base_animation_name
	cur_img.frames.update_frames(seq_name, sequence)
	cur_img.animation = seq_name
	restart()


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
			printt("delay transition", dur_s / 2.0)
			_next_transition_delay.time_left = dur_s / 2.0
		else:
			_next_transition_delay = get_tree().create_timer(dur_s / 2.0)
			printt("start delay", dur_s / 2.0)
			await _next_transition_delay.timeout
			printt("offset transition")
			cur_img.next_frame()
	else:
		cur_img.next_frame() # immediately advance to sync to beat
