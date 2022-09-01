extends Node2D

@export_node_path(Label) var _frameNode
@export_node_path(Label) var _totalFramesNode
@export_node_path(Label) var _actualFrameNode
@export_node_path(Label) var _runningTotalFramesNode

var gui := false

# transitions
var transition := true
var transition_tween : Tween
var transition_cutoff := 0.042 # 24 fps = 0.042
var _prevTexture : Texture2D
var _next_transition_delay : SceneTreeTimer



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

	
func _on_animated_sprite_2d_frame_changed():
	# update GUI
	if gui:
		_frameNode.text = str($AnimatedSprite2D.frame)
		if $AnimatedSprite2D.animation == $AnimatedSprite2D.custom_animation:
			_actualFrameNode.text = str($AnimatedSprite2D.current_sequence[$AnimatedSprite2D.frame])
		else:
			_actualFrameNode.text = str($AnimatedSprite2D.frame)
		_runningTotalFramesNode.text = str( _runningTotalFramesNode.text.to_int() + 1)
		_totalFramesNode.text = str($AnimatedSprite2D.frame_counts[$AnimatedSprite2D.animation])
	
	# update crossfade
	# https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult
	#$CrossfadeImage.material.set_shader_param("startTime", Time.get_ticks_msec() / 1000.0)
	#$CrossfadeImage.material.set_shader_param("duration", speed_scale / fps)
	#$CrossfadeImage.material.set_shader_param("prevTex", $CrossfadeImage.material.get_shader_param("curTex"))
	#$CrossfadeImage.material.set_shader_param("curTex", frames.get_frame(animation, frame))
	
	if transition:
		if _prevTexture != null:
			$PrevImage.texture = _prevTexture
		_prevTexture = $AnimatedSprite2D.get_current_frame()
		if $PrevImage.texture != null:
			var duration = $AnimatedSprite2D.get_frame_duration()
			#printt("frame change", $AnimatedSprite2D.frame, duration)
			# HACK: when duration is low then start more transparent
			var from = clampf(duration * 2.0, 0.5, 1.0) 
			if duration > transition_cutoff:
				$PrevImage.visible = true
				# copy scale and offset
				# (luckily this works because this signal seems to be processed before the AnimatedSPite is updated, phew)
				if $AnimatedSprite2D.stretch:
					$PrevImage.scale = $AnimatedSprite2D.scale
					$PrevImage.offset = $AnimatedSprite2D.offset
				transition_tween = get_tree().create_tween()
				transition_tween.tween_property($PrevImage, "modulate:a", 0.0, duration).from(from)
				# TODO: if different size then fade in the new image for half the duration?
			else:
				$PrevImage.visible = false


func load_images(image_paths: Array, animation_name : String, loaderFn, max_duration_ms : float) -> Texture2D:
	return $AnimatedSprite2D.create_frames_timed(Loader.image_files, animation_name, loaderFn, max_duration_ms)


func load_image_pack(file_path : String):
	$AnimatedSprite2D.set_sprite_frames(ResourceLoader.load(file_path))
	$AnimatedSprite2D.save_path = file_path


func load_sequence(file_path : String):
	var sequence = Loader.load_sequence_file(file_path)
	var sequence_name = file_path.get_file().get_basename()
	if sequence_name != "":
		$AnimatedSprite2D.add_sequence(sequence_name, sequence)
		$AnimatedSprite2D.change_animation(sequence_name) # switch to loaded sequence


func get_total_frame_count() -> int:
	if $AnimatedSprite2D.frames == null: return 0
	
	var count := 0
	for anim in $AnimatedSprite2D.frames.get_animation_names():
		count += $AnimatedSprite2D.frames.get_frame_count(anim)
	return count


func get_frame_count(anim_name : String = "") -> int:
	if $AnimatedSprite2D.frames == null: return 0
	
	if anim_name == "":
		anim_name = $AnimatedSprite2D.animation
		
	return $AnimatedSprite2D.frames.get_frame_count(anim_name)


func get_spriteframes() -> SpriteFrames:
	return $AnimatedSprite2D.frames


func get_frames(anim_name : String = "") -> Array:
	if anim_name == "":
		anim_name = $AnimatedSprite2D.animation
		
	var sp = get_spriteframes()
	var count = get_frame_count()
	var frames = Array()
	for i in get_frame_count():
		# add sequence number to the frames meta data
		var t2d = sp.get_frame(anim_name, i)
		t2d.set_meta(anim_name, i)
		frames.append(t2d)
	return frames


func get_current_frame_index() -> int:
	return $AnimatedSprite2D.frame


func get_sequence_name() -> String:
	return $AnimatedSprite2D.animation


func get_sequence(seq_name : String = "") -> PackedInt32Array:
	if seq_name == "":
		return $AnimatedSpride2D.current_sequence
	else:
		return $AnimatedSprite2D.sequences[seq_name]


func update_sequence(seq_name : String, sequence : PackedInt32Array) -> void:
	$AnimatedSprite2D.pause()
	$AnimatedSprite2D.animation = "default"
	$AnimatedSprite2D.update_sequence(seq_name, sequence)
	$AnimatedSprite2D.animation = seq_name
	restart()


func get_save_path() -> String:
	return $AnimatedSprite2D.save_path


func save_frames(file_path : String) -> int:
	return $AnimatedSprite2D.save_frames(file_path)


func pause():
	$AnimatedSprite2D.pause()
	if transition_tween.is_valid() and transition_tween.is_running():
		transition_tween.pause()
	
	
func resume():
	$AnimatedSprite2D.resume()
	if transition_tween.is_valid():
		transition_tween.play()


func restart():
	$AnimatedSprite2D.pause()
	$PrevImage.visible = false
	if transition_tween.is_valid() and transition_tween.is_running():
		transition_tween.stop()
	$AnimatedSprite2D.frame = 0
 

func set_timing(duration_ms : float):
	var dur_s = duration_ms / 1000.0
	$AnimatedSprite2D.set_frame_duration(dur_s)
	if  transition_tween.is_valid() and transition_tween.is_running():
		transition_tween.stop()
	$PrevImage.visible = false
	#$AnimatedSprite2D.next_frame() # immediately advance to sync to beat
	
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
			$AnimatedSprite2D.next_frame()
	else:
		$AnimatedSprite2D.next_frame() # immediately advance to sync to beat
