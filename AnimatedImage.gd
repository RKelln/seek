extends AnimatedSprite2D

var base_animation_name : String = "default"
var compress := true
@export var pack_name : String = "":
	get:
		if not sprite_frames: return ""
		return sprite_frames.pack_name
	set(value):
		if sprite_frames:
			sprite_frames.pack_name = value
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
var mouse_controls := false

var paused : bool = false

var frame_counts : Dictionary
var current_frame : Dictionary

var _direction : float = 1.0
var _anim_fps : float = 0
var _requested_animation : bool = false # tracks if animation change has been requested
var _current_texture : Texture2D # reference to current texture
var _index : int
var _speeds : Dictionary # stores current speeds for each animation
var _tag_keys_pressed : Dictionary = {} # "key": bool where True is pressed

var listening_for_tags := false

signal real_frame_changed(frame: int)

# Called when the node enters the scene tree for the first time.
func _ready():
	#if not sprite_frames: return
	
	self.frame_changed.connect(_on_frame_changed)
	
	var animations = sprite_frames.get_animation_names()
	if animations.size() == 0:
		print("No animations!")
	
	if base_animation_name not in animations:
		print("no default animation!")
	if not sprite_frames.has_animation(base_animation_name) or sprite_frames.get_frame_count(base_animation_name) == 0:
		print("no default or has no frames!")
		# try to fix:
		for anim_name in animations:
			if sprite_frames.get_frame_count(anim_name) > 0:
				print("recreating new base animation from ", anim_name)
				sprite_frames.copy_frames(anim_name, base_animation_name)
				break
	
	# set up frame_counts and current_frame
	var start_anim : String
	for animation_name in animations:
		_add_animation(animation_name)
		if animation_name != base_animation_name:
			start_anim = animation_name
	
	# start with last animation
	_init_animation(start_anim)
	_change_animation(start_anim)
	
	debug_info()

	play(animation, _direction)
	paused = false


func _on_frame_changed():
	# update current frame
	if not _requested_animation:
		# some hacky magic here, we don't want to update more than once
		if current_frame[animation] != frame:
			var seq : AnimatedSequence = sequence()
			current_frame[animation] = seq.next(_direction)
			frame = current_frame[animation]
			#printt(_index, "frame", frame)
			_current_texture = seq.get_frame_texture(sprite_frames, frame)
#			if sequences[current_sequence].active_flags > 0:
#				prints(frame, sequences[current_sequence].tags())
			real_frame_changed.emit(frame)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if sprite_frames == null or frame_counts[animation] == 0: return

	# slows things down but if images are all different sizes this can make them appear more similar
	if is_playing() and stretch: # per frame
		rescale()
	
#	if Input.is_anything_pressed():
#		handle_input()


func _mouse_control_speed() -> void:
	var mpos := get_viewport().get_mouse_position()
	var viewsize := get_viewport().get_visible_rect().size
	var relative_dist = remap(mpos.x, 0, viewsize.x, -1.0, 1.0)
	change_relative_speed_normalized(relative_dist)
	get_viewport().set_input_as_handled()
	#printt(viewsize.x, mpos.x, relative_dist)


func _unhandled_input(event : InputEvent):
	if not active:
		return
		
	if mouse_controls:
		# no mouse motion events handled here
		if event is InputEventMouseMotion: 
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_SHIFT):
					return
				_mouse_control_speed()
			return
	
	if event is InputEventTargetedAction:
		# note: do not check for pressed, 
		#       as these events may have strength
		#       that changes throughout a "press"
		#print(event.as_text())
		match event.action:
			"set_speed":
				if valid_target(event.target):
					set_speed(event.strength, event.target)
			"set_flag":
				var flag = int(event.target)
	if mouse_controls:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				stop()
				var w : float = float(get_viewport().get_visible_rect().size.x)
				# NOTE: leave a small amount on each side the is always start and end of sequence
				goto_frame(int(remap(get_viewport().get_mouse_position().x, 0.1 * w, 0.9 * w, 0, frame_counts[animation])))
				#printt("jump to", get_viewport().get_mouse_position().x, frame)

	# allow when playing or not:

	if event.is_action_pressed("play_toggle", false, true):
		if is_playing():
			_pause()
		else:
			_resume()
			
	if not is_playing():
		# allow for frame skip
		if event.is_action_pressed("skip_forward", true, true):
			next_frame(1)
		elif event.is_action_pressed("skip_backward", true, true):
			next_frame(-1)
	
		# other input requires scenes to be playing:
		return
	
	if mouse_controls:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# no modifier keys pressed
				if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_SHIFT):
					return
				_mouse_control_speed()
			return # no other mouse events below
	
	# handle tags:
	# activate tags for all keys that were pressed while shift was held
	if event is InputEventKey and is_instance_valid(sequence().mapping):
		print(event)
		if event.keycode == KEY_SHIFT:
			if event.pressed:
				listening_for_tags = true
			else:
				listening_for_tags = false
				# activate tags
				var flags := 0
				if _tag_keys_pressed.size() == 0:
					# clear tags
					prints("deactivating tags")
					sequence().active_flags = 0
				else:
					for keycode in _tag_keys_pressed:
						if _tag_keys_pressed[keycode]:
							_tag_keys_pressed[keycode] = false
							flags |= sequence().mapping.key_flag(keycode)
					_tag_keys_pressed.clear()
					prints("activating tags", sequence().mapping.flags_to_tags(flags))
					sequence().active_flags = flags
			return
		elif event.shift_pressed: # shift is held
			if event.pressed:
				if sequence().mapping.key_exists(event.keycode):
					_tag_keys_pressed[event.keycode] = true
					prints("selecting tag", event.keycode)
					get_viewport().set_input_as_handled()
			return
			
	# no shift modifier:
	
	# repeatable actions:
	if event.is_action_pressed("fast_forward", true, true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, 1.0)
		
	elif event.is_action_pressed("fast_backward", true, true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, -1.0)
	elif event.is_action_pressed("step_forward", true, true): # allow echo
		next_frame(1)
	elif event.is_action_pressed("step_backward", true, true): # allow echo
		next_frame(-1)
	
	# non-repeated actions:
	elif event.is_action_pressed("skip_forward", false, true):
		next_frame(frame_skip)
	elif event.is_action_pressed("skip_backward", false, true):
		next_frame(-frame_skip)
	elif event.is_action_pressed("faster", false, true):
		speed *= 1.05
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("slower", false, true):
		speed /= 1.05
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("reverse", false, true):
		reverse()
	elif event.is_action_pressed("next_animation", false, true):
		change_animation(next_animation(1))
	elif event.is_action_pressed("speed_reset", false, true):
		speed = 1.0
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("random", false, true):
		goto_frame(randi() % frame_counts[animation])

	# on release
	elif (event.is_action_released("fast_forward", true)
		or event.is_action_released("fast_backward", true)):
		# resume normal play
		speed_scale = speed
		if paused:
			pause()
		else:
			play(animation, _direction)
	

func valid_target(index : int = -1) -> bool:
	if index < 0 and not active: return false
	if index >= 0 and index != _index : return false
	return true


func change_animation_relative(direction : int, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	change_animation(next_animation(direction))
	
	
func _init_animation(animation_name : String) -> void:
	# ensure that values are there, and set as base animation if values missing
	if animation_name in sprite_frames.sequences:
		_anim_fps = sprite_frames.get_fps(animation_name)
		if animation_name not in frame_counts:
			frame_counts[animation_name] = sprite_frames.get_frame_count(animation_name)
	else:
		printt("Warning: init_animation:", animation_name, "not found, using base animation")
		_anim_fps = sprite_frames.get_fps(base_animation_name)
		if animation_name not in frame_counts:
			frame_counts[animation_name] = sprite_frames.get_frame_count(base_animation_name)
	if animation_name not in _speeds:
		_speeds[animation_name] = 1.0
	if animation_name not in current_frame:
		current_frame[animation_name] = 0
	assert(_anim_fps > 0)
	
	frame_skip = mini(max_frame_skip, maxi(1, floor(frame_counts[animation_name] * percent_frames_for_skip))) # % of frames
	speed = _speeds[animation_name]
	speed_scale = speed


func _add_animation(animation_name : String) -> void:
	if animation_name not in current_frame:
		current_frame[animation_name] = 0
		
	if animation_name not in _speeds:
		_speeds[animation_name] = 1.0
	
	# use base animation frame count as default (to support sequences)
	var frame_count = sprite_frames.get_frame_count(base_animation_name)
	if animation_name in sprite_frames.get_animation_names():
		frame_count =  sprite_frames.get_frame_count(animation_name)
			
	if animation_name not in frame_counts or frame_counts[animation_name] <= 0:
		frame_counts[animation_name] = frame_count


# always changes animation, regardless of current and state
func _change_animation(requested_animation : String) -> void:
	printt(_index, "change animation to ", requested_animation, "_anim_fps:", _anim_fps, "frame_skip:", frame_skip, "speed:", speed)

	if requested_animation not in sprite_frames.sequences: 
		printt(_index, "no animation found:", requested_animation)
		return

	# NOTE: when changing animations it signals frame_changed and sets the frame back to the start
	_requested_animation = true # now that this is set, it won't update current_frame or signal real_frame_changed
	animation = requested_animation
	_requested_animation = false
	
	print(animation, sprite_frames.sequences)
	goto_frame(sequence().current_value())
	_current_texture = sequence().get_frame_texture(sprite_frames, frame)
	
	if stretch: rescale()


func change_animation(requested_animation : String) -> void:
	if not active: return
	#printt(_index, "animated.change_animation", requested_animation)
	if frame_counts[requested_animation] <= 0:
		return

	# always set these:
	_init_animation(requested_animation)
	
	if requested_animation == animation:
		return
		
	_change_animation(requested_animation)


func info() -> Dictionary:
	var i : Dictionary
	if sprite_frames:
		i = sprite_frames.info()
	return i
	

func debug_info():
	print(info())
	print("Animations: ", sprite_frames.get_animation_names())
	# TODO: print("Sequences: ", get_valid_sequence_names())
	print("Current sequence: ", animation)
	print("Frame count: ", frame_counts[animation])
	
	
func next_animation(inc : int) -> StringName:
	var anim_names = sprite_frames.get_valid_animation_names()
	var i = anim_names.find(animation)
	for anim in anim_names: # loop maximum of once
		i = fposmod(i + inc, anim_names.size())
		# never switch to base animation and
		# skip animations with no frames
		if anim_names[i] != base_animation_name and frame_counts[anim_names[i]] > 0: 
			return StringName(anim_names[i])
	return animation


func get_frame_duration() -> float:
	var relative_duration = sprite_frames.get_frame_duration(animation, frame)
	var absolute_duration = relative_duration / (sprite_frames.get_animation_speed(animation) * abs(get_playing_speed()))
	return absolute_duration
	#assert(_anim_fps > 0)
	#return (1.0 / _anim_fps) / speed_scale


func get_current_frame() -> Texture2D:
	#return sprite_frames.get_frame_texture(animation, frame)
	return _current_texture


func get_texture(seq_name : String = "", index : int = -1) -> Texture2D:
	if seq_name == "": seq_name = base_animation_name
	# FIXME: this is silly, there should be a better call path to this
	return sprite_frames.sequences[seq_name].get_frame_texture(sprite_frames, index)


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
	

func next_frame(increment : int = _direction) -> void:
	printt(_index, "next_frame", increment)
	if increment > 0 and increment < 1:
		increment = 1
	elif increment < 0 and increment > -1:
		increment = -1
	#frame = floor(fposmod(frame + increment, frame_counts[animation]))
	goto_frame(sequence().next(increment))


func goto_frame(f : int) -> void:
	current_frame[animation] = f
	frame = f
	_current_texture = sequence().get_frame_texture(sprite_frames, frame)


func sequence() -> AnimatedSequence:
	return sprite_frames.sequences[animation]

# TODO: without underscore this overrides the existing pause and needs to be changed
func _pause():
	if is_playing():
		pause()
		paused = true


func _resume():
	if not is_playing():
		play(animation, _direction)
		paused = false


func rescale():
	var viewsize : Vector2 = get_viewport().get_visible_rect().size # Vector2(1920, 1080) # FIXME: get these from project settings? # get_viewport().sizes
	if _current_texture:
		var framesize := _current_texture.get_size()
		var viewscale : float = min( float(viewsize.x) / float(framesize.x), float(viewsize.y) / float(framesize.y))
		if not is_equal_approx(viewscale, scale.x):
			scale = Vector2(viewscale, viewscale)
			# bug in godot 4 requires offset adjustment?
			offset = Vector2i( viewsize.x / viewscale, viewsize.y / viewscale ) * 0.5
			offset = Vector2i( 1920 / viewscale, 1080 / viewscale ) * 0.5
		#printt(viewsize, framesize, viewscale, scale, offset)


func skip_frame(direction : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	#printt(_index, "skip_frame", frame_skip, direction)
	# default to skip 0.3sec or 1 of frames whatever is less, but allow for direction to modulate
	if is_playing():
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
		play(animation, _direction)


func set_speed(normalized_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	speed = remap(normalized_speed, 0.0, 1.0, 0.0, max_speed)
	printt(_index, "set_speed", normalized_speed, speed)
	
	speed_scale = speed 
	if not is_playing() and speed > 0:
		play(animation, _direction)



func change_relative_speed_normalized(normalized_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	normalized_speed = clampf(normalized_speed, -1.0, 1.0)
	
	var eased := ease(abs(normalized_speed), 2)
	var max_speed = max(5.0, 30.0 / _anim_fps)
	speed = remap(eased, 0, 1.0, 0, max_speed)
	printt(_index, "change_normalized_speed", normalized_speed, eased, speed, _anim_fps)
	speed_scale = speed 
	
	if normalized_speed < 0:
		_direction = -1.0
		play(animation, _direction)
	else:
		_direction = 1.0
		play(animation, _direction)


func reverse(layer : int = -1) -> void:
	if not valid_target(layer): return
	
	_direction = -_direction
	play(animation, _direction)



