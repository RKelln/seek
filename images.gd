extends Node2D

@export_node_path(Label) var _frameNode
@export_node_path(Label) var _totalFramesNode
@export_node_path(Label) var _actualFrameNode
@export_node_path(Label) var _runningTotalFramesNode

var transition := true
var gui := true

var _prevTexture : Texture2D
var _anim_fps : float  # stores animation fps (only done when animation starts)

func _init_node(nodeOrPath, defaultPath) -> Node:
	if nodeOrPath is Node:
		return nodeOrPath
	elif nodeOrPath is NodePath:
		return get_node(nodeOrPath)
	else:
		return get_parent().find_child(defaultPath)

# Called when the node enters the scene tree for the first time.
func _ready():
	_frameNode = _init_node(_frameNode, "Frame")
	_totalFramesNode = _init_node(_totalFramesNode, "TotalFrames")
	_actualFrameNode = _init_node(_actualFrameNode, "ActualFrame")
	_runningTotalFramesNode = _init_node(_runningTotalFramesNode, "RunningTotal")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


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
			# HACK: when duration is low then start more transparent
			var from = clampf(duration * 2.0, 0.5, 1.0) 
			if duration > 0.042: # 24 fps
				$PrevImage.visible = true
				# copy scale and offset
				# (luckily this works because this signal seems to be processed before the AnimatedSPite is updated, phew)
				if $AnimatedSprite2D.stretch:
					$PrevImage.scale = $AnimatedSprite2D.scale
					$PrevImage.offset = $AnimatedSprite2D.offset
				var tween = get_tree().create_tween()
				tween.tween_property($PrevImage, "modulate:a", 0.0, duration).from(from)
				# TODO: if differnet size then fade in the new image for half the duration?
			else:
				$PrevImage.visible = false


func load_image_pack(file_path):
	$AnimatedSprite2D.set_sprite_frames(ResourceLoader.load(file_path))
	$AnimatedSprite2D.save_path = file_path


func get_total_frame_count():
	var count := 0
	for anim in $AnimatedSprite2D.frames.get_animation_names():
		count += $AnimatedSprite2D.frames.get_frame_count(anim)
	return count
