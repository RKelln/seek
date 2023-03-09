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

var paused : bool = false

var frame_counts : Dictionary
var current_frame : Dictionary

# dictionary of named Sequences
# Sequences are associated to an animation, either with the same name or the default/base animation
var sequences : Dictionary = {}
var current_sequence : StringName

var _backwards := false
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
	
	# test tags
#	var tag_data := Loader.load_tag_file("user://migration_tags.txt")
#	if tag_data:
#		var tags : Dictionary = tag_data[0]
#		var flags : PackedInt64Array = tag_data[1]
#		sequences[start_anim].flags = flags
#		sequences[start_anim].set_mapping(tag_data[2])
#		print(start_anim, sequences[start_anim].mapping)
#
#	# test neighbours
#	var neighbours_data := Loader.load_neighbours_file("user://migration_200_neighbours.txt")
#	sequences[start_anim] = AnimatedMultiSequence.from_AnimatedSequence(sequences[start_anim], neighbours_data, 
#		Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.NEIGHBOURS)

	debug_info()

	play(animation)
	paused = false


func _on_frame_changed():
	# update current frame
	if not _requested_animation:
		
		# some hacky magic here, we don't want to update more than once
		if current_frame[current_sequence] != frame:
			current_frame[current_sequence] = sequences[current_sequence].next()
			frame = current_frame[current_sequence]
			
			_current_texture = sequences[animation].get_frame_texture(sprite_frames, frame)
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


func _unhandled_input(event : InputEvent):
	if not active:
		return
	# no mouse motion events handled here
	if event is InputEventMouseMotion: return
	
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
				prints("set_flag", event, sequences[current_sequence].mapping.flag_tag(flag))
				sequences[current_sequence].active_flags = flag

				
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			stop()
			var w : float = float(get_viewport().get_visible_rect().size.x)
			# NOTE: leave a small amount on each side the is always start and end of sequence
			frame = int(remap(get_viewport().get_mouse_position().x, 0.1 * w, 0.9 * w, 0, frame_counts[animation]))
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
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# no modifier keys pressed
			if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_SHIFT):
				return
			var mpos := get_viewport().get_mouse_position()
			var viewsize := get_viewport().get_visible_rect().size
			var relative_dist = remap(mpos.x, 0, float(mpos.x), -1.0, 1.0)
			change_relative_speed_normalized(relative_dist)
			get_viewport().set_input_as_handled()
			#printt(w, get_viewport().get_mouse_position().x, relative_dist, dist)
		return # no other mouse events below
	
	# handle tags:
	# activate tags for all keys that were pressed while shift was held
	if event is InputEventKey and is_instance_valid(sequences[current_sequence].mapping):
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
					sequences[current_sequence].active_flags = 0
				else:
					for keycode in _tag_keys_pressed:
						if _tag_keys_pressed[keycode]:
							_tag_keys_pressed[keycode] = false
							flags |= sequences[current_sequence].mapping.key_flag(keycode)
					_tag_keys_pressed.clear()
					prints("activating tags", sequences[current_sequence].mapping.flags_to_tags(flags))
					sequences[current_sequence].active_flags = flags
			return
		elif event.shift_pressed: # shift is held
			if event.pressed:
				if sequences[current_sequence].mapping.key_exists(event.keycode):
					_tag_keys_pressed[event.keycode] = true
					prints("selecting tag", event.keycode)
					get_viewport().set_input_as_handled()
			return
			
	# no shift modifier:
	
	# repeatable actions:
	if event.is_action_pressed("fast_forward", true, true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, false)
		
	elif event.is_action_pressed("fast_backward", true, true): # allow echo
		speed_scale = frame_skip * speed
		play(animation, true)
	# non-repeated actions:
	elif event.is_action_pressed("skip_forward", true, true):
		next_frame(frame_skip)
	elif event.is_action_pressed("skip_backward", true, true):
		next_frame(-frame_skip)
	elif event.is_action_pressed("faster", true, true):
		speed *= 1.25
		print("speed:", speed)
		speed_scale = speed
	elif event.is_action_pressed("slower", true, true):
		speed /= 1.25
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
		frame = randi() % frame_counts[animation]

	# on release
	elif (event.is_action_released("fast_forward", true)
		or event.is_action_released("fast_backward", true)):
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
	if animation_name in sequences:
		_anim_fps = sprite_frames.get_animation_speed(base_animation_name)
	else:
		_anim_fps = sprite_frames.get_animation_speed(animation_name)
	assert(_anim_fps > 0)
	
	frame_skip = mini(max_frame_skip, maxi(1, floor(frame_counts[animation_name] * percent_frames_for_skip))) # % of frames
	speed = _speeds[animation_name]
	speed_scale = speed
	if animation_name not in frame_counts:
		frame_counts[animation_name] = sprite_frames.get_frame_count(animation_name)


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
	
	if animation_name not in sequences:
		# TODO: pass in actual frame indices
		sequences[animation_name] = AnimatedSequence.new(frame_count, animation_name, frame_count)


# always changes animation, regardless of current and state
func _change_animation(requested_animation : String) -> void:
	printt(_index, "change animation to ", requested_animation, "_anim_fps:", _anim_fps, "frame_skip:", frame_skip, "speed:", speed)

	# NOTE: when changing animations it signals frame_changed and sets the frame back to the start
	_requested_animation = true # now that this is set, it won't update current_frame or signal real_frame_changed
	animation = requested_animation
	current_sequence = animation
	_requested_animation = false
	
	#frame = current_frame[animation] # sets current frame
	frame = sequences[current_sequence].current_value()
	#_current_texture = sprite_frames.get_frame_texture(animation, frame)
	_current_texture = sequences[current_sequence].get_frame_texture(sprite_frames, frame)
	
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
	if sprite_frames:
		i = sprite_frames.info()
	return i
	

func debug_info():
	print(info())
	print("Animations: ", sprite_frames.get_animation_names())
	# TODO: print("Sequences: ", get_valid_sequence_names())
	print("Current sequence: ", current_sequence)
	print("Frame count: ", frame_counts[current_sequence])
	
	
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
	assert(_anim_fps > 0)
	return (1.0 / _anim_fps) / speed_scale


func get_current_frame() -> Texture2D:
	#return sprite_frames.get_frame_texture(animation, frame)
	return _current_texture


func get_texture(seq_name : String = "", index : int = -1) -> Texture2D:
	return sequences[seq_name].get_frame_texture(index) 


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
	#frame = floor(fposmod(frame + increment, frame_counts[animation]))
	frame = sequences[animation].next(increment)


# TODO: without underscore this overrides the existing pause and needs to be changed
func _pause():
	if is_playing():
		stop()
		paused = true


func _resume():
	if not is_playing():
		play(animation, _backwards)
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
		play(animation, _backwards)


func set_speed(normalized_speed : float = 0.0, layer : int = -1) -> void:
	if not valid_target(layer): return
	
	speed = remap(normalized_speed, 0.0, 1.0, 0.0, max_speed)
	printt(_index, "set_speed", normalized_speed, speed)
	
	speed_scale = speed 
	if not is_playing() and speed > 0:
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



