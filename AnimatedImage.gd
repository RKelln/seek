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
@export var active : bool = false:
	get:
		return active
	set(on):
		if active and on: return
		if not active and not on: return
		active = on

const max_speed : float = 10.0
const max_speed_fps : float = 30.0
var speed : float = 1.0 :
	get:
		return speed
	set(value):
		speed = value
		_speeds[animation] = value

const percent_frames_for_skip = 0.02
const max_frame_skip = 10
var frame_skip = 10
var stretch := true

var paused : bool = false

var frame_counts : Dictionary
var current_frame : Dictionary

var _backwards := false
var _anim_fps : float = 0
var _requested_animation : bool = false # tracks if animation change has been requested
var _current_texture : Texture2D # reference to current texture
var _index : int
var _speeds : Dictionary # stores current speeds for each animation


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
	var start_anim : String
	for animation_name in animations:
		if animation_name not in current_frame:
			current_frame[animation_name] = 0
			
		if animation_name not in _speeds:
			_speeds[animation_name] = 1.0
		
		if animation_name not in frame_counts or frame_counts[animation_name] <= 0:
			# something has gone wrong
			frame_counts[animation_name] = frames.get_frame_count(animation_name)
	
		if animation_name != base_animation_name:
			start_anim = animation_name
	
	# start with last animation
	_init_animation(start_anim)
	_change_animation(start_anim)
	
	print("Animations: ", animations)
	print("Current animation: ", animation)
	print("Frame count: ", frame_counts[animation])

	play(animation)
	paused = false


func _on_frame_changed():
	# update current frame
	if not _requested_animation:
		current_frame[animation] = frame
		_current_texture = frames.get_frame_texture(animation, frame)
		real_frame_changed.emit(frame)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if frames == null or frame_counts[animation] == 0: return

	# slows things down but if iamges are all different sizes this can make them appear more similar
	if playing and stretch: # per frame
		rescale()
	
#	if Input.is_anything_pressed():
#		handle_input()


func _unhandled_input(event : InputEvent):
	if not active:
		return
	# no mouse motion events handled here
	if event is InputEventMouseMotion: return
	
	if event is InputEventTargetedAction:
		# note: do not check for pressed, 
		#       as these events may have strength
		#       that changes throughout a "press"
		if valid_target(event.target):
			print(event.as_text())
			match event.action:
				"set_speed":
					set_speed(event.strength, event.target)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			stop()
			var w : float = float(get_viewport().get_visible_rect().size.x)
			# NOTE: leave a small amount on each side the is always start and end of sequence
			frame = int(remap(get_viewport().get_mouse_position().x, 0.1 * w, 0.9 * w, 0, frame_counts[animation]))
			#printt("jump to", get_viewport().get_mouse_position().x, frame)

	# allow when playing or not:

	if event.is_action_pressed("play_toggle"):
		if playing:
			pause()
		else:
			resume()
			
	if not playing:
		# allow for frame skip
		if event.is_action_pressed("skip_forward"):
			next_frame(1)
		elif event.is_action_pressed("skip_backward"):
			next_frame(-1)
	
		# other input requires scenes to be playing:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var w : float = float(get_viewport().get_visible_rect().size.x)
			var relative_dist = remap(get_viewport().get_mouse_position().x, 0, w, -1.0, 1.0)
			
			change_relative_speed_normalized(relative_dist)
			#printt(w, get_viewport().get_mouse_position().x, relative_dist, dist)
		return # no other mouse events below
		
	# repeatable actions:
	if event.is_action_pressed("fast_forward", true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, false)
	elif event.is_action_pressed("fast_backward", true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, true)
	# non-repeated actions:
	elif event.is_action_pressed("skip_forward"):
		next_frame(frame_skip)
	elif event.is_action_pressed("skip_backward"):
		next_frame(-frame_skip)
	elif event.is_action_pressed("faster"):
		speed *= 1.25
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("slower"):
		speed /= 1.25
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("reverse"):
		reverse()
	elif event.is_action_pressed("next_animation"):
		change_animation(next_animation(1))
	elif event.is_action_pressed("speed_reset"):
		speed = 1.0
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("random"):
		frame = randi() % frame_counts[animation]

	# on release
	elif (event.is_action_released("fast_forward")
		or event.is_action_released("fast_backward")):
		# resume normal play
		speed_scale = speed
		if paused:
			stop()
		else:
			play(animation, _backwards)
	

func valid_target(index : int = -1) -> bool:
	if index < 0 and not active: return false
	if index >= 0 and index != _index : return false
	return true


func change_animation_relative(direction : int, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	change_animation(next_animation(direction))
	
	
func _init_animation(animation_name : String) -> void:
	_anim_fps = frames.get_animation_speed(animation_name)
	assert(_anim_fps > 0)
	frame_skip = mini(max_frame_skip, maxi(1, floor(frames.get_frame_count(animation_name) * percent_frames_for_skip))) # % of frames
	speed = _speeds[animation_name]
	speed_scale = speed
	if animation_name not in frame_counts:
		frame_counts[animation_name] = frames.get_frame_count(animation_name)

# always changes animation, regardless of current and state
func _change_animation(requested_animation : String) -> void:
	printt(_index, "change animation to ", requested_animation, "_anim_fps:", _anim_fps, "frame_skip:", frame_skip, "speed:", speed)

	# NOTE: when changing animations it signals frame_changed and sets the frame back to the start
	_requested_animation = true # now that this is set, it won't update current_frame or signal real_frame_changed
	animation = requested_animation
	_requested_animation = false
	
	frame = current_frame[animation] # sets current frame
	_current_texture = frames.get_frame_texture(animation, frame)
	
	if stretch: rescale()


func change_animation(requested_animation : String) -> void:
	if not active: return
	#printt(_index, "animated.change_animation", requested_animation)
	if frame_counts[requested_animation] <= 0:
		return

	# alsways set these:
	_init_animation(requested_animation)
	
	if requested_animation == animation:
		return
		
	_change_animation(requested_animation)


func info() -> Dictionary:
	var i : Dictionary
	if frames:
		i = frames.info()
	return i
	
	
func next_animation(inc : int) -> StringName:
	var anim_names = frames.get_valid_animation_names()
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
	#return frames.get_frame_texture(animation, frame)
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
	printt(_index, "next_frame", increment)
	if increment > 0 and increment < 1:
		increment = 1
	elif increment < 0 and increment > -1:
		increment = -1
	frame = floor(fposmod(frame + increment, frame_counts[animation]))


func pause():
	if playing:
		stop()
		paused = true


func resume():
	if not playing:
		play(animation, _backwards)
		paused = false




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


func skip_frame(direction : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	#printt(_index, "skip_frame", frame_skip, direction)
	# default to skip 0.3sec or 1 of frames whatever is less, but allow for direction to modulate
	if playing:
		next_frame(direction * clampi(0.3 * _anim_fps * speed, 1, frame_skip))
	else:
		next_frame(sign(direction))


func change_relative_speed(relative_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	if speed <= 2.0 and speed > 0.1:
		speed *= 1.0 + (relative_speed / speed * 0.05)
	elif speed > 2.0:
		speed += relative_speed * speed * 0.1
	else:
		speed += relative_speed * 0.05
	printt(_index, "change_relative_speed", relative_speed, speed, _anim_fps)
	
	speed = clampf(speed, 0.0, max_speed)
	speed_scale = speed 
	if speed > 0:
		play(animation, _backwards)


func set_speed(normalized_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	speed = remap(normalized_speed, 0.0, 1.0, 0.0, max_speed)
	printt(_index, "set_speed", normalized_speed, speed)
	
	speed_scale = speed 
	if speed > 0:
		play(animation, _backwards)



func change_relative_speed_normalized(normalized_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	normalized_speed = clampf(normalized_speed, -1.0, 1.0)
	
	#var rdist2 = remap(normalized_speed, -0.5, 0.5, -0.2, 0.2) # less change near the middle
	#speed = 0.5 * (abs(normalized_speed) + abs(rdist2)) * _anim_fps * 20.0 # FIXME: add fps here?
	
	var eased := ease(abs(normalized_speed), 2)
	if _anim_fps < 1:
		speed = remap(eased, 0, 1.0, 0, 10.0 + 90.0 * (1.0 - _anim_fps))
	elif _anim_fps < 10:
		speed = remap(eased, 0, 1.0, 0, 5.0 + 9.0 * (10.0 - _anim_fps))
	else:
		speed = remap(eased, 0, 1.0, 0, 5.0)
	printt(_index, "change_normalized_speed", normalized_speed, eased, speed, _anim_fps)
	
	speed = clampf(speed, 0.0, 100.0)
	
	speed_scale = speed 
	
	if normalized_speed < 0:
		_backwards = true
		play(animation, _backwards)
	else:
		_backwards = false
		play(animation, _backwards)


func reverse(layer : int = -1) -> void:
	if not valid_target(layer): return
	
	_backwards = !_backwards
	play(animation, _backwards)



