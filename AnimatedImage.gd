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


func create_frames_timed(image_paths: Array, animation_name : String, loaderFn, max_duration_ms : float) -> void:
	if frames == null:
		frames = SpriteFrames.new()
	if not frames.get_animation_names().has(animation_name):
		frames.add_animation(animation_name)
		frame_counts[animation_name] = 0
	
	var count = 0
	var start = Time.get_ticks_msec()
	var duration = 0.0
	for image_path in image_paths:
		count += 1
		if count <= frame_counts[animation_name]: continue
		print("Loading ", image_path)
		frames.add_frame(animation_name, Loader.load_texture(image_path))
		var f = frames.get_frame(animation_name, frame_counts[animation_name])
		print(f, f.get_size())
		frame_counts[animation_name] += 1
		duration = (Time.get_ticks_msec() - start)
		if duration >= max_duration_ms:
			break
	print("Loading time (msec): ", duration)




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




func add_sequence(animation_name, sequence : PackedInt32Array, default_fps=30.) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, default_fps)
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


func save_frames(file_path : String) -> int:
	save_path = file_path
	print("Saving: ", file_path)
	var start := Time.get_ticks_msec()
	print(frames)
	var result := ResourceSaver.save(file_path, frames, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_BUNDLE_RESOURCES)
	print("Saving time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )
	for anim in frames.get_animation_names():
		for i in range(frames.get_frame_count(anim)):
			var frame = frames.get_frame(anim, i)
			print(i, frame, frame.get_size())
	return result


# Called when the node enters the scene tree for the first time.
func _ready():
	var animations = frames.get_animation_names()
	if animations.size() == 0:
		print("No animations!")
	
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if frames == null: return
	
	var frame_count = frame_counts[animation]
	if frame_count == 0:
		return
		
	# slows things down but if iamges are all different sizes this can make them appear more similar
	if stretch: # per frame
		var viewsize : Vector2 = get_viewport().size
		var framesize := frames.get_frame(animation, frame).get_size()
		var viewscale : float = min( viewsize.x / framesize.x, viewsize.y / framesize.y)
		if viewscale != 1.0:
			scale = Vector2(viewscale, viewscale)
			# bug in godot 4 requires offset adjustment?
			offset = Vector2(viewsize.x * (1.0 / viewscale) / 2.0,  viewsize.y * (1.0 / viewscale) / 2.0)
			#print(framesize, viewscale, scale, offset)
	
	if Input.is_action_just_pressed('next_animation'):
		change_animation(next_animation(1))

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
			frame = fposmod(frame + frame_skip, frame_count)
		else:
			frame = fposmod(frame + 1, frame_count)
	elif Input.is_action_just_pressed("skip_backward"):
		if playing:
			frame = fposmod(frame - frame_skip, frame_count)
		else:
			frame = fposmod(frame - 1, frame_count)
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
		frame = randi() % frame_count

