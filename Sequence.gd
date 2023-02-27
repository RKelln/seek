class_name Sequence extends Resource

# Simple Sequence

# A sequence that stores ints in order. Each int also has a bitflag that can be used for masking.

var values := PackedInt32Array()
var flags := PackedInt64Array()
var filtered_indices : Array[int]
var current_f_index : int

enum BIT_FLAGS { 
	NONE = 0, 
	F1 = 1,
	F2 = 1 << 1,
	F3 = 1 << 2,
	F4 = 1 << 3,
	F5 = 1 << 4,
	F6 = 1 << 5,
	F7 = 1 << 6,
	F8 = 1 << 7,
}
const ALL_FLAGS = 9223372036854775807 # max int 64

var current_index : int = 0:
	get:
		return current_index
	set(value):
		current_index = clampi(value, 0, values.size() - 1)
		
var active_flags : int = 0: 
	get:
		return active_flags
	set(value):
		active_flags = value
		if active_flags > 0:
			filter_values(active_flags)


enum LOOP_TYPE {NONE, LOOP, PINGPONG}
var loop := LOOP_TYPE.LOOP
var _direction : int = 1


func _init(initial_values : Variant, loop_type := LOOP_TYPE.LOOP) -> void:
	assert(initial_values is int || initial_values is Array)
	loop = loop_type
	
	if initial_values is int:
		values = range(initial_values)
	elif initial_values is Array:
		values = initial_values


func value(i : int = -1) -> int:
	if i == -1: i = current_index
	return values[i]


func current_value() -> int:
	assert(current_index >= 0)
	return values[current_index]


func flag(i : int = -1) -> int:
	if i == -1: i = current_index
	return flags[i]


func filter_values(bitmask : int = 0) -> void:
	filtered_indices.clear()
	current_f_index = -1  # represents that the current index may not be part of the filtered set
	for i in values.size():
		if bitmask & flags[i] == bitmask:
			filtered_indices.append(i)
			# retain the current index if possible
			# TODO: optimize?
			if i <= current_index:
				current_f_index = filtered_indices.size() - 1


func get_filtered_values() -> PackedInt32Array:
	return filtered_indices.map(func(i): return values[i])


func get_values() -> PackedInt32Array:
	if active_flags > 0:
		return get_filtered_values()
	return values


func max_value() -> int:
	return Array(values).max()


func min_value() -> int:
	return Array(values).min()


func next(inc : int = 1) -> int:
	var i : int 
	var size : int
	if active_flags == 0:
		i = current_index
		size = values.size()
	else:
		i = current_f_index
		size = filtered_indices.size()
	
	# edge case, start with the first
	# (typically this is only when current_index isn't part of the filtered set)
	if i < 0: i = 0
	
	if inc != 0 and size > 1:
		match loop:
			LOOP_TYPE.LOOP:
				i = (i + (_direction * inc)) % size
			LOOP_TYPE.NONE:
				i += _direction * inc
			LOOP_TYPE.PINGPONG:
				var steps : int = abs(inc)
				while steps > 0:
					steps -= 1
					i += _direction * sign(inc)
					if i < 0:
						_direction = -_direction
						i = 1 # one from start
					elif i >= size:
						_direction = -_direction
						i = size - 2 # one from end
	
		if active_flags == 0:
			current_index = i
		else:
			current_f_index = i
			current_index = filtered_indices[current_f_index]

	return values[current_index]
