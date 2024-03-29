extends Node

const EASE_IN_OUT = -1.6521
const MAX_FREQUENCY = 20.0
const MAX_AMPLITUDE = 20.0
const FREQUENCY_CYCLE = 7.0 # seconds (a 1 second cycle seems really fast)

@export var min_val : float = 0.0
@export var max_val : float = 1.0
@export var amplitude : float = 0.0
@export_range(0.0, MAX_FREQUENCY) var frequency : float = 0.0
@export_exp_easing var easing : float = EASE_IN_OUT
# seconds to hold at the extremes
@export_range(0.0, 10.0, 0.1, "or_greater") var hold : float = 0.0 
# percentage to fuzz the min and max values each cycle
@export_range(0.0, 1.0) var fuzz : float = 0.0 
# if the maximum value should be centered on the minimum i.e. min=0, max=1 then values will be -0.5 to 0.5
@export var centered := false
@export var self_process : bool = false

@export var value : float = 0.0
@export var direction : float = 1.0

@export var frequency_input : StringName
@export var frequency_inc_input : StringName
@export var frequency_dec_input : StringName
@export var frequency_input_strength := 1.0

@export var amplitude_input : StringName
@export var amplitude_inc_input : StringName
@export var amplitude_dec_input : StringName
@export var amplitude_input_strength := 1.0

var paused := false
var progress : float = 0
var held_duration : float = -1
var curr_min : float
var curr_max : float
var target : float = INF


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_values()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	if paused: return
	if self_process and frequency > 0 and amplitude > 0:
		value = _update_value(value, curr_min, curr_max, amplitude, frequency, easing, delta)
	
	
func _unhandled_input(event) -> void:
	if paused: return
	
	if frequency_input != "" and event.is_action_pressed(frequency_input):
		frequency = event.get_action_strength()
	if amplitude_input != "" and event.is_action_pressed(amplitude_input):
		amplitude = event.get_action_strength()


func input_poll(delta : float) -> void:
	if frequency_inc_input != "" and Input.is_action_pressed(frequency_inc_input):
		frequency = clampf(frequency + delta * frequency_input_strength, 0.0, MAX_FREQUENCY)
		printt(name, frequency_inc_input, frequency)
		
	if frequency_dec_input != "" and Input.is_action_pressed(frequency_dec_input):
		frequency = clampf(frequency - delta * frequency_input_strength, 0.0, MAX_FREQUENCY)
		printt(name, frequency_dec_input, frequency)

	if amplitude_inc_input != "" and Input.is_action_pressed(amplitude_inc_input):
		amplitude = clampf(amplitude + delta * amplitude_input_strength, 0.0, MAX_AMPLITUDE)
		printt(name, amplitude_inc_input, amplitude)

	if amplitude_dec_input != "" and Input.is_action_pressed(amplitude_dec_input):
		amplitude = clampf(amplitude - delta * amplitude_input_strength, 0.0, MAX_AMPLITUDE)
		printt(name, amplitude_dec_input, amplitude)


func process(delta : float) -> float:
	if paused: return value
	
	input_poll(delta)
	if frequency > 0 and amplitude > 0:
		value = _update_value(value, curr_min, curr_max, amplitude, frequency, easing, delta)

	return value


func set_target(t : float) -> void:
	target = t
	if centered:
		# we don't want to set min
		if curr_max < curr_min:
			if target < curr_max or target > curr_min:
				curr_max = target
		if curr_max > curr_min:
			if target > curr_max or target < curr_min:
				curr_max = target
	else:
		curr_max = target
		

func unset_target() -> void:
	target = INF
	update_values()
	

func update_values() -> void:
	update_min()
	update_max()
	if curr_max < curr_min:
		direction = -1.0
		value = clampf(value, curr_max, curr_min)
	else:
		direction = 1.0
		value = clampf(value, curr_min, curr_max)


func update_min() -> void:
	# if there is a target and its closer to the min then set the min to the target
	if target != INF and not centered:
		if abs(target - curr_min) < abs(target - curr_max):
			printt(name, "set min to target", target, "min:", curr_min, "max:" , curr_max)
			curr_min = target
			return

	if centered:
		# curr_max could be below or above
		# min values of 0 never have fuzz
		if fuzz > 0 and min_val != 0:
			var half_max = max_val * 0.5
			curr_min = randf_range(min_val - (min_val - half_max) * fuzz,
									min_val + (min_val - half_max) * fuzz )
		else:
			curr_min = min_val
	else:
		if fuzz:
			# fuzzes towards max
			curr_min = min_val + randf() * fuzz * abs(max_val - min_val)
		else:
			curr_min = min_val
#	if curr_min == curr_max:
#		print(name, "min", curr_min, curr_max, min_val, max_val)


func update_max() -> void:
	# if there is a target and its closer to the max then set the max to the target
	if target != INF:
		if centered or abs(target - curr_max) < abs(target - curr_min):
			printt(name, "set max to target", target, "min:", curr_min, "max:" , curr_max)
			curr_max = target
			return

	var fuzz_scaler = randf_range(1.0-fuzz, 1.0) 
	if centered:
		# randomly choose above or below min
		var dir = sign(randf_range(-1,1))
		curr_max = min_val + dir * (max_val * 0.5) * fuzz_scaler
	else:
		curr_max = max_val * fuzz_scaler
#	if curr_min == curr_max:
#		print(name, "max", curr_min, curr_max, min_val, max_val)


func _update_value(current : float, minv : float, maxv : float, 
	_amplitude : float, _frequency : float, _easing : float, delta : float) -> float:
	
	if hold > 0.0 and held_duration >= 0.0:
		held_duration += delta
		if held_duration > hold:
			delta = held_duration - hold
			held_duration = -1.0
		else:
			return current

	progress = progress + _frequency / FREQUENCY_CYCLE * delta * direction
	if progress <= 0:
		if hold:
			progress = 0.0
			held_duration = 0.0
		else:
			progress = -progress
		direction = 1.0
		update_max()
	elif progress >= 1.0:
		if hold:
			progress = 1.0
			held_duration = 0.0
		else:
			progress = 1.0 - (progress - 1.0)
		direction = -1.0
		update_min()
		
	if target != INF:
		# blend in target
		maxv = (1.0 - delta) * maxv + delta * target
	var dist := (maxv - minv) * _amplitude
	if dist == 0:
		#printt(name, minv, maxv, _amplitude)
		return current
	var v := lerpf(minv, minv + dist, ease(progress, _easing))

	# once we arrive at target set to INF
	if target != INF and is_equal_approx(abs(v - target), 0.0):
		target = INF
#	if int(snappedf(progress, 0.01) * 100) % 25 == 0:
#		printt(name, snappedf(progress, 0.01), v, minv, maxv, target, abs(v - target))
	return v
	
