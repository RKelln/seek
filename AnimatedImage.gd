extends AnimatedSprite2D

var base_animation_name : String = "default"
# '/media/storage/media/Datasets/nebula/'
# '/media/storage/media/Datasets/cliff_waves/'
# '/media/storage/media/Datasets/beach_trees/'
# '/home/ryankelln/Documents/Projects/Gifts/Laura Soch/Birthday 2021/slideshow/food/rotated'
# '/media/storage/media/Datasets/Alexandra/plant_stills_hd'
#var image_dir : String = '/media/storage/media/Datasets/Alexandra/plant_stills_hd'
#var saved_sequence : String = 'plant_stills_2k_hash_sequence_144179.txt'
#var file_list_path : String = '' #'seasons_filelist.txt'
var compress := true
#var max_images : int = 0
#var max_image_size := Vector2(1920, 1080)

var speed := 1.0
var fps := 30
var frame_skip = 10
var stretch := true
var sequences : Dictionary
var current_sequence : PackedInt32Array
var seq_frame : int = 0
var custom_animation : String
var paused : bool = false

var save_path : String
var frame_counts : Dictionary

var _backwards := false
var _anim_fps : float



func create_frames(image_paths: Array, animation_name : String, loaderFn) -> void:
	var start := Time.get_ticks_msec()
	if frames == null:
		frames = SpriteFrames.new()
	if not frames.get_animation_names().has(animation_name):
		frames.add_animation(animation_name)
		
	for image_path in image_paths:
		#print("Loading ", image_path)
		frames.add_frame(animation_name, loaderFn.call(image_path))
		frame_counts[animation_name] += 1
	print("Loading time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )


func create_frames_timed(image_paths: Array, animation_name : String, loaderFn, max_duration_ms : float) -> Texture2D:
	if frames == null:
		frames = SpriteFrames.new()
	if not frames.get_animation_names().has(animation_name):
		frames.add_animation(animation_name)
		frame_counts[animation_name] = 0
	
	var count = 0
	var start = Time.get_ticks_msec()
	var duration = 0.0
	var tex : Texture2D
	for image_path in image_paths:
		count += 1
		if count <= frame_counts[animation_name]: continue
		#print("Loading ", image_path)
		tex = Loader.load_texture(image_path)
		frames.add_frame(animation_name, tex)
		#var f = frames.get_frame(animation_name, frame_counts[animation_name])
		#print(f, f.get_size())
		frame_counts[animation_name] += 1
		duration = (Time.get_ticks_msec() - start)
		if duration >= max_duration_ms:
			break
	#print("Loading time (msec): ", duration)
	return tex




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


func add_sequence(animation_name : String, sequence : PackedInt32Array, default_fps=30.) -> void:
	if animation_name in frames.get_animation_names():
		prints(animation_name, "already exists")
		return
	
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, default_fps)
	frames.set_animation_loop(animation_name, true)
	sequences[animation_name] = Array()
	
	_create_sequence(animation_name, sequence)


func _create_sequence(animation_name : String, sequence : PackedInt32Array, from_anim : String = base_animation_name) -> void:
	var max_frame := frames.get_frame_count(from_anim)
	assert(max_frame > 0, "_create_sequence(): max_frame == 0")
	if animation_name not in sequences:
		sequences[animation_name] = Array()
		
	for i in sequence:
		# get texture from default animation
		if i < max_frame:
			frames.add_frame(animation_name, frames.get_frame(from_anim, i))
			sequences[animation_name].append(i)


func update_sequence(animation_name : String, sequence : PackedInt32Array) -> void:
	if animation_name not in frames.get_animation_names():
		prints(animation_name, "doesn't exist")
		return
	
	frames.clear(animation_name)
	sequences[animation_name].clear()
	_create_sequence(animation_name, sequence)


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


func save_frames(file_path : String) -> int:
	save_path = file_path
	print("Saving: ", file_path)
	var start := Time.get_ticks_msec()
	var result := ResourceSaver.save(frames, file_path, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_BUNDLE_RESOURCES)
	print("Saving time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )
	return result


# Called when the node enters the scene tree for the first time.
func _ready():
	var animations = frames.get_animation_names()
	if animations.size() == 0:
		print("No animations!")
	
	if base_animation_name not in animations:
		print("no default animation!")
	if frames.get_frame_count(base_animation_name) == 0:
		print("default animation has no frames!")
		# try to fix:
		for anim_name in animations:
			if frames.get_frame_count(anim_name) > 0:
				print("recreating new base animation from ", anim_name)
				_create_sequence(base_animation_name, range(frames.get_frame_count(anim_name)), anim_name)
				break
		
	# set up base sequence if it doesn't already exist 
	# assume animation images in order
	for animation_name in animations:
		if animation_name not in frame_counts or frame_counts[animation_name] <= 0:
			# something has gone wrong
			frame_counts[animation_name] = frames.get_frame_count(animation_name)
		if frame_counts[animation_name] > 0:
			animation = animation_name
			if animation_name not in sequences:
				print("No sequence for animation: ", animation_name)
				sequences[animation_name] = range(frame_counts[animation_name])

	print("Animations: ", animations)
	print("Current animation: ", animation)
	print("Frame count: ", frame_counts[animation])

	change_animation(animation)
	play(animation)
	paused = false


#func rescale_images():
#	if stretch:
#		var viewsize : Vector2 = get_viewport().size
#		var framesize := frames.get_frame(animation, frame).get_size()
#		var viewscale : float = min( viewsize.x / framesize.x, viewsize.y / framesize.y)
#		if viewscale != 1.0:
#			scale = Vector2(viewscale, viewscale)


func next_animation(inc : int) -> StringName:
	var anim_names = frames.get_animation_names()
	var i = anim_names.find(animation)
	for anim in anim_names: # loop maximum of once
		i = fposmod(i + inc, anim_names.size())
		if frame_counts[anim_names[i]] > 0: # skip animations with no frames
			return StringName(anim_names[i])
	return animation


func get_frame_duration() -> float:
	return (1.0 / _anim_fps) / speed_scale


func get_current_frame() -> Texture2D:
	return frames.get_frame(animation, frame)


func set_frame_duration(duration_s : float) -> void:
	var default_speed = 1.0 / _anim_fps
	speed = default_speed / duration_s
	speed_scale = speed
	

func next_frame(increment : int = 1) -> void:
	frame = fposmod(frame + increment, frame_counts[animation])


func pause():
	if playing:
		stop()
		paused = true


func resume():
	if not playing:
		play(animation, _backwards)
		paused = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if frames == null or frame_counts[animation] == 0: return

	# slows things down but if iamges are all different sizes this can make them appear more similar
	if stretch: # per frame
		var viewsize : Vector2 = get_viewport().size
		var tex = frames.get_frame(animation, frame)
		if tex:
			var framesize := tex.get_size()
			var viewscale : float = min( viewsize.x / framesize.x, viewsize.y / framesize.y)
			if viewscale != 1.0:
				scale = Vector2(viewscale, viewscale)
				# bug in godot 4 requires offset adjustment?
				offset = Vector2(viewsize.x * (1.0 / viewscale) / 2.0,  viewsize.y * (1.0 / viewscale) / 2.0)
				#print(framesize, viewscale, scale, offset)
	
	if Input.is_anything_pressed():
		handle_input()


func handle_input():
	if Input.is_action_just_pressed("playtoggle"):
		if playing:
			pause()
		else:
			resume()
	
	# other input requires squenes to be playing:
	if paused: return 
	
	if Input.is_action_just_pressed('next_animation'):
		change_animation(next_animation(1))
		
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
			next_frame(frame_skip)
		else:
			next_frame(1)
	elif Input.is_action_just_pressed("skip_backward"):
		if playing:
			next_frame(-frame_skip)
		else:
			next_frame(-1)
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
		frame = randi() % frame_counts[animation]
