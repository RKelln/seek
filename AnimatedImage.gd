extends AnimatedSprite2D

var base_animation_name : String = "images"
# '/media/storage/media/Datasets/nebula/'
# '/media/storage/media/Datasets/cliff_waves/'
# '/media/storage/media/Datasets/beach_trees/'
# '/home/ryankelln/Documents/Projects/Gifts/Laura Soch/Birthday 2021/slideshow/food/rotated'
# '/media/storage/media/Datasets/Alexandra/plant_stills_hd'
var image_dir : String = '/media/storage/media/Datasets/Alexandra/plant_stills_hd'
var saved_sequence : String = 'plant_stills_2k_hash_sequence_144179.txt'
var file_list_path : String = '' #'seasons_filelist.txt'
var compress := true
var max_images : int = 0
var max_image_size := Vector2(1920, 1080)

var speed := 1.0
var fps := 30
var frame_skip = 10
var stretch := true
var sequences : Dictionary
var current_sequence : PackedInt32Array
var seq_frame : int = 0
var custom_animation : String
var paused : bool = false

var _frame_count := 0
var _backwards := false
var _prevTexture : Texture2D
var _anim_fps : float  # stores animation fps (only done when animation starts)
	
@export_node_path(Label) var _frameNode
@export_node_path(Label) var _totalFramesNode
@export_node_path(Label) var _actualFrameNode
@export_node_path(Label) var _runningTotalFramesNode



func load_image(image_path: String) -> Image:
	var image = Image.new()
	
	if image.load(image_path) != OK:
		printerr("Failed to load:", image_path)
		image.create(1920, 1080, false, Image.FORMAT_RGB8) # FORMAT_RGB8 or FORMAT_ETC2_RGB8
	
	assert(image is Image)
	
	# resize to max HD
#	if image.x > max_image_size.x or image.y > max_image_size.y:
#		var image_size = _get_new_size(Vector2(1920,1080), image.get_size())
#		image.resize(image_size.x, image_size.y, Image.INTERPOLATE_CUBIC)
	
	#print("compressed: ", image.is_compressed())
	#image.lock()
	if compress:
		image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_SRGB, 0.7)
	#print("compressed: ", image.is_compressed())
	return image


func load_texture(file_path : String) -> Texture:
	var texture : Texture
	if file_path.begins_with('res://'):
		texture = load(file_path)
	else: # load from external file
		var img = load_image(file_path)
		texture = ImageTexture.new()
		texture.create_from_image(img)
		#print(texture.get_format())
		assert(texture is ImageTexture)
		
		if stretch:
			if texture.get_width() < texture.get_height(): # portrait
				var viewscale = get_viewport().size.y / texture.get_height()
				if viewscale != 1.0:
					# stech height to viewport height
					texture.set_size_override(Vector2(texture.get_width() * viewscale, texture.get_height() * viewscale))
			else: # landscape
				var viewscale = get_viewport().size.x / texture.get_width()
				if viewscale != 1.0:
					# stech height to viewport height
					texture.set_size_override(Vector2(texture.get_width() * viewscale, texture.get_height() * viewscale))
	return texture


func create_frames(spriteframes: SpriteFrames, image_paths: Array, animationName : String) -> void:
	var start := Time.get_ticks_msec()
	for image_path in image_paths:
		#print("Loading ", image_path)
		spriteframes.add_frame(animationName, load_texture(image_path))
		_frame_count += 1
	print("Loading time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )


#func create_animation( animationName : String, sequenceArray : PackedInt32Array) -> void:
#	frames.add_animation(animationName)
#	frames.set_animation_speed(animationName, fps)
#	frames.set_animation_loop(animationName, true)
#	var max_frame := frames.get_frame_count(base_animation_name)
#	for i in sequenceArray:
#		# get texture from default animation
#		if i < max_frame:
#			frames.add_frame(animationName, frames.get_frame(base_animation_name, i))
#

func _init_node(nodeOrPath, defaultPath) -> Node:
	if nodeOrPath is Node:
		return nodeOrPath
	elif nodeOrPath is NodePath:
		return get_node(nodeOrPath)
	else:
		return get_parent().find_child(defaultPath)


func add_sequence(animation_name, sequence : PackedInt32Array, fps=30.) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, fps)
	frames.set_animation_loop(animation_name, true)
	sequences[animation_name] = Array()
	
	var max_frame := frames.get_frame_count(base_animation_name)
	for i in sequence:
		# get texture from default animation
		if i < max_frame:
			frames.add_frame(animation_name, frames.get_frame(base_animation_name, i))
			sequences[animation_name].append(i)
	
			
func add_image(animation_name, texture):
	frames.add_frame(animation_name, texture)
	
	
func add_images(animation_name, images):
	for image in images:
		add_image(animation_name, image)


#	# create custom animation
#	if saved_sequence != "" and saved_sequence.is_valid_filename() and saved_sequence.get_file() != "":
#		sequence = _load_sequence(saved_sequence)
#		assert(sequence.size() > 0)
#		print("Using sequence from", saved_sequence)
#		# create new animation
#		custom_animation = "custom_" + saved_sequence.get_basename()
#		create_animation(custom_animation, sequence)
#		_active_animation = custom_animation
#
#	else:
#		_active_animation = animation_name
#
#	play(_active_animation, _backwards)
	
func change_animation(requested_animation : String) -> void:
	animation = requested_animation
	current_sequence = sequences[animation]
	_anim_fps = frames.get_animation_speed(animation)
	
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_frameNode = _init_node(_frameNode, "Frame")
	_totalFramesNode = _init_node(_totalFramesNode, "TotalFrames")
	_actualFrameNode = _init_node(_actualFrameNode, "ActualFrame")
	_runningTotalFramesNode = _init_node(_runningTotalFramesNode, "RunningTotal")

	# set up base sequence if it doesn't already exist 
	# assume animation images in order
	if base_animation_name not in sequences:
		sequences[base_animation_name] = range(frames.get_frame_count(base_animation_name))

	change_animation(animation)
	play(animation)
	paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if frames == null: return
	
	_frame_count = frames.get_frame_count(animation)
	if _frame_count == 0:
		return
		
	if stretch:
		var viewsize : Vector2 = get_viewport().size
		var framesize := frames.get_frame(base_animation_name, frame).get_size()
		var viewscale : float = min( viewsize.x / framesize.x, viewsize.y / framesize.y)
		if viewscale != 1.0:
			scale = Vector2(viewscale, viewscale)
	
	if Input.is_action_just_pressed('next_animation'):
		if animation == base_animation_name:
			change_animation(custom_animation)
		else:
			change_animation(base_animation_name)
	
	if Input.is_action_just_pressed("playtoggle"):
		if playing:
			stop()
			paused = true
		else:
			play(animation, _backwards)
			paused = false
	
	if Input.is_action_just_pressed("reverse"):
		_backwards = !_backwards
		play(animation, _backwards)
	
	if Input.is_action_just_pressed("faster"):
		speed *= 1.25
		print("speed:", speed)
	elif Input.is_action_just_pressed("slower"):
		speed /= 1.25
		print("speed:", speed)
	elif Input.is_action_just_pressed("speed_reset"):
		speed = 1.0
		print("speed:", speed)
		
	speed_scale = speed
	
	if Input.is_action_just_pressed("skip_forward"):
		if playing:
			frame = fposmod(frame + frame_skip, _frame_count)
		else:
			frame = fposmod(frame + 1, _frame_count)
	elif Input.is_action_just_pressed("skip_backward"):
		if playing:
			frame = fposmod(frame - frame_skip, _frame_count)
		else:
			frame = fposmod(frame - 1, _frame_count)
	if Input.is_action_pressed("fast_forward"):
		speed_scale = 2 * speed
		play(animation, false)
	elif Input.is_action_pressed("fast_backward"):
		speed_scale = 2 * speed
		play(animation, true)
	elif Input.is_action_just_released("fast_forward") or Input.is_action_just_released("fast_backward"):
		# resume normal play
		if paused:
			stop()
		else:
			play(animation, _backwards)
	
	if Input.is_action_just_pressed("random"):
		frame = randi() % _frame_count


func _on_images_frame_changed():
	# update GUI
	_frameNode.text = str(frame)
	if animation == custom_animation:
		_actualFrameNode.text = str(current_sequence[frame])
	else:
		_actualFrameNode.text = str(frame)
	_runningTotalFramesNode.text = str( _runningTotalFramesNode.text.to_int() + 1)
	_totalFramesNode.text = str(_frame_count)
	
	# update crossfade
	# https://stackoverflow.com/questions/68765045/tween-the-texture-on-a-texturebutton-texturerect-fade-out-image1-while-simult
	#$CrossfadeImage.material.set_shader_param("startTime", Time.get_ticks_msec() / 1000.0)
	#$CrossfadeImage.material.set_shader_param("duration", speed_scale / fps)
	#$CrossfadeImage.material.set_shader_param("prevTex", $CrossfadeImage.material.get_shader_param("curTex"))
	#$CrossfadeImage.material.set_shader_param("curTex", frames.get_frame(animation, frame))
	
	
	if _prevTexture != null:
		$PrevImage.texture = _prevTexture
	_prevTexture = frames.get_frame(animation, frame)
	if $PrevImage.texture != null:
		var duration = (1.0 / _anim_fps) / speed_scale
		# HACK: when duration is low then start more transparent
		var from = clampf(duration * 2.0, 0.5, 1.0) 
		if duration > 0.042: # 24 fps
			$PrevImage.visible = true
			var tween = get_tree().create_tween()
			tween.tween_property($PrevImage, "modulate:a", 0.0, duration).from(from)
		else:
			$PrevImage.visible = false
