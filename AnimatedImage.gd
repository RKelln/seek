extends AnimatedSprite2D

var base_animation_name : String = "default"
var compress := true
@export var pack_name : String = "":
	get:
		if not frames: return ""
		return frames.pack_name
	set(value):
		if frames:
			frames.pack_name = value

var speed := 1.0
var frame_skip = 10
var stretch := true

var paused : bool = false

var frame_counts : Dictionary
var current_frame : Dictionary

var _backwards := false
var _anim_fps : float = 0
var _requested_animation : bool = false # tracks if animation change has been requested
var _current_texture : Texture2D # reference to current texture

signal real_frame_changed(frame: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	#if not frames: return
	
	self.frame_changed.connect(_on_frame_changed)
	
	var animations = frames.get_animation_names()
	if animations.size() == 0:
		print("No animations!")
	
	if base_animation_name not in animations:
		print("no default animation!")
	if not frames.has_animation(base_animation_name) or frames.get_frame_count(base_animation_name) == 0:
		print("no default or has no frames!")
		# try to fix:
		for anim_name in animations:
			if frames.get_frame_count(anim_name) > 0:
				print("recreating new base animation from ", anim_name)
				frames.copy_frames(anim_name, base_animation_name)
				break
	
	# set up frame_counts and current_frame
	for animation_name in animations:
		if animation_name not in current_frame:
			current_frame[animation_name] = 0
		
		if animation_name not in frame_counts or frame_counts[animation_name] <= 0:
			# something has gone wrong
			frame_counts[animation_name] = frames.get_frame_count(animation_name)
	
	# start with last animation
	change_animation(animations[-1])

	_anim_fps = frames.get_animation_speed(animation)
	
	print("Animations: ", animations)
	print("Current animation: ", animation)
	print("Frame count: ", frame_counts[animation])

	play(animation)
	paused = false


func _on_frame_changed():
	# update current frame
	if not _requested_animation:
		current_frame[animation] = frame
		_current_texture = frames.get_frame(animation, frame)
		real_frame_changed.emit(frame)


func change_animation(requested_animation : String) -> void:
	if requested_animation == animation:
		return
	if frame_counts[requested_animation] <= 0:
		return

	# NOTE: when changing animations it signals frame_changed and sets the frame back to the start
	_requested_animation = true # now that this is set, it won't update current_frame or signal real_frame_changed
	animation = requested_animation
	_requested_animation = false
	
	frame = current_frame[animation] # sets current frame
	_anim_fps = frames.get_animation_speed(animation)
	assert(_anim_fps > 0)
	frame_skip = maxi(1, floor(frames.get_frame_count(animation) * 0.1))
	printt("change animation to ", requested_animation, current_frame[animation])


func info() -> Dictionary:
	var i : Dictionary
	if frames:
		i = frames.info()
	return i
	
	
func next_animation(inc : int) -> StringName:
	var anim_names = frames.get_animation_names()
	var i = anim_names.find(animation)
	for anim in anim_names: # loop maximum of once
		i = fposmod(i + inc, anim_names.size())
		# never switch to base animation and
		# skip animations with no frames
		if anim_names[i] != base_animation_name and frame_counts[anim_names[i]] > 0: 
			return StringName(anim_names[i])
	return animation


func get_frame_duration() -> float:
	assert(_anim_fps > 0)
	return (1.0 / _anim_fps) / speed_scale


func get_current_frame() -> Texture2D:
	#return frames.get_frame(animation, frame)
	return _current_texture


func get_rect() -> Rect2:
	var size = get_current_frame().get_size()
	var pos = offset
	if centered:
		pos -= 0.5 * size
	return Rect2(pos, size)


func set_frame_duration(duration_s : float) -> void:
	assert(_anim_fps > 0)
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
	if playing and stretch: # per frame
		rescale()
	
#	if Input.is_anything_pressed():
#		handle_input()


func rescale():
	var viewsize : Vector2 = get_viewport().get_visible_rect().size # Vector2(1920, 1080) # FIXME: get these from project settings? # get_viewport().size
	if _current_texture:
		var framesize := _current_texture.get_size()
		var viewscale : float = min( viewsize.x / framesize.x, viewsize.y / framesize.y)
		if not is_equal_approx(viewscale, scale.x):
			scale = Vector2(viewscale, viewscale)
			# bug in godot 4 requires offset adjustment?
			offset = Vector2( viewsize.x / viewscale, viewsize.y / viewscale ) * 0.5
			#printt(viewsize, framesize, viewscale, scale, offset)


func _input(event : InputEvent) -> void:
	
	# shift + number key: change animation
	if event is InputEventKey:
		if event.pressed:
			if event.echo == false and event.shift_pressed:
				var anims := frames.get_animation_names()
				var count := anims.size()
				var selected_anim := 0
				match event.physical_keycode:
					KEY_1:
						selected_anim = 1
					KEY_2:
						selected_anim = 2
					KEY_3:
						selected_anim = 3
					KEY_4:
						selected_anim = 4
					KEY_5:
						selected_anim = 5
					KEY_6:
						selected_anim = 6
					KEY_7:
						selected_anim = 7
					KEY_8:
						selected_anim = 8
					KEY_9:
						selected_anim = 9
					KEY_0:
						selected_anim = 10
				if selected_anim > 0 and selected_anim <= count:
					printt("AnimatedImage input", event.physical_keycode, selected_anim)
					change_animation(anims[selected_anim - 1])
	
			if event.is_action_pressed("skip_forward"):
				print("sf", frame_skip)
				if playing:
					next_frame(frame_skip)
				else:
					next_frame(1)
			elif event.is_action_pressed("skip_backward"):
				print("sb", frame_skip)
				if playing:
					next_frame(-frame_skip)
				else:
					next_frame(-1)


func handle_input():
	if Input.is_action_just_pressed("play_toggle"):
		if playing:
			pause()
		else:
			resume()
	
	# other input requires scenes to be playing:
	if paused: 
		# allow frame by frame during pause
		if Input.is_action_just_pressed("skip_forward"):
			next_frame(1)
		elif Input.is_action_just_pressed("skip_backward"):
				next_frame(-1)
		
		
		return 
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var w : float = float(get_viewport().get_visible_rect().size.x)
		var relative_dist = remap(get_viewport().get_mouse_position().x, 0, w, -1.0, 1.0)
		var rdist2 = remap(relative_dist, -0.3, 0.3, -0.1, 0.1) # less change near the middle
		speed = 0.5 * (abs(relative_dist) + abs(rdist2)) * 100.0

		if relative_dist < 0:
			_backwards = true
			play(animation, _backwards)
		else:
			_backwards = false
			play(animation, _backwards)
			
		#printt(w, get_viewport().get_mouse_position().x, relative_dist, dist)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		stop()
		var w : float = float(get_viewport().get_visible_rect().size.x)
		# NOTE: leave a small amount on each side the is always start and end of sequence
		frame = int(remap(get_viewport().get_mouse_position().x, 0.1 * w, 0.9 * w, 0, frame_counts[animation]))
	elif not playing:
		play(animation, _backwards)
			
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
	
#	if Input.is_action_just_pressed("skip_forward"):
#		if playing:
#			next_frame(frame_skip)
#		else:
#			next_frame(1)
#	elif Input.is_action_just_pressed("skip_backward"):
#		if playing:
#			next_frame(-frame_skip)
#		else:
#			next_frame(-1)
	if Input.is_action_pressed("fast_forward"):
		speed_scale = frame_skip * speed
		play(animation, false)
	elif Input.is_action_pressed("fast_backward"):
		speed_scale = frame_skip * speed
		play(animation, true)
	elif Input.is_action_just_released("fast_forward") or Input.is_action_just_released("fast_backward"):
		# resume normal play
		speed_scale = speed
		if paused:
			stop()
		else:
			play(animation, _backwards)
	
	if Input.is_action_just_pressed("random"):
		frame = randi() % frame_counts[animation]
