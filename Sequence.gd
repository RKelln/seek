class_name Sequence extends Resource

# Simple Sequence

# A sequence that stores ints in order. Each int also has a bitflag that can be used for masking.

var values := PackedInt32Array()
var flags := PackedInt64Array(): set = set_flags
var filtered_indices : Array[int]
var current_f_index : int

enum BitFlags { 
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
		
var active_flags : int = 0: set = set_active_flags

enum LoopType {NONE, LOOP, PINGPONG}
var loop := LoopType.LOOP
var _direction : int = 1

## Record tag information and mapping to flags
## See: Loader.load_tag_file()
var mapping : TagFlagKeyMap


func _init(initial_values : Variant, flags : Variant = [], loop_type := LoopType.LOOP) -> void:
	assert(initial_values is int or initial_values is Array or initial_values is PackedInt32Array)
	loop = loop_type
	
	if initial_values is int:
		values = PackedInt32Array(range(initial_values))
	else:
		values = PackedInt32Array(initial_values)
	
	set_flags(flags)


func set_mapping(mapping : TagFlagKeyMap) -> void:
	self.mapping = mapping
	

func value(i : int = -1) -> int:
	if i == -1: i = current_index
	return values[i]


func get_value(i : int = -1) -> int:
	if i == -1: i = current_index
	return values[i]


func current_value() -> int:
	assert(current_index >= 0)
	return values[current_index]


func size() -> int:
	return values.size()


func set_flags(f : Variant):	
	if flags is PackedInt64Array:
		flags = f
	else:
		flags = PackedInt64Array(f)
	if flags.size() != values.size():
		if flags.size() > 0:
			print("Warning: size of flags ({0}) does not match size of values ({1})".format([flags.size(), values.size()]))
		flags.resize(values.size())


func set_active_flags(bitmask : int) -> void:
	if bitmask > 0 and active_flags != bitmask:
		filter_values(bitmask)
	active_flags = bitmask


func flag(i : int = -1) -> int:
	if i == -1: i = current_index
	return flags[i]


func filter_values(bitmask : int = 0) -> void:
	if active_flags == bitmask: return
	filtered_indices.clear()
	current_f_index = -1  # represents that the current index may not be part of the filtered set
	if bitmask == 0: return
	for i in values.size():
		if bitmask & flags[i] == bitmask:
			filtered_indices.append(i)
			# retain the current index if possible
			# TODO: optimize?
			if i <= current_index:
				current_f_index = filtered_indices.size() - 1


func get_filtered_values() -> PackedInt32Array:
	if filtered_indices.size() == 0:
		return values
	return filtered_indices.map(func(i): return values[i])


func get_values() -> PackedInt32Array:
	if active_flags > 0:
		return get_filtered_values()
	return values


func max_value() -> int:
	return Array(values).max()


func min_value() -> int:
	return Array(values).min()


func get_active_index() -> int:
	if active_flags == 0:
		return current_index
	else:
		return current_f_index


## Returns the current index
func set_active_index(i : int) -> int:
	if active_flags == 0:
		current_index = i
	else:
		current_f_index = i
		current_index = filtered_indices[current_f_index]
	return current_index


func get_active_size() -> int:
	if active_flags == 0:
		return values.size()
	else:
		return filtered_indices.size()


## Updated the current_index to a valid value based on active_flags
## Returns the number of filtered indices
func filter_current_index() -> int:
	if active_flags == 0 or filtered_indices.size() == 0: return values.size()

	if current_f_index >= 0 and current_index != filtered_indices[current_f_index]:
		current_index = filtered_indices[current_f_index]
	else:
		current_index = filtered_indices[0]
	return filtered_indices.size()


func next(inc : int = 1) -> int:
	var i : int = get_active_index()
	var size : int = get_active_size()

	# edge case, start with the first
	# (typically this is only when current_index isn't part of the filtered set)
	if i < 0: i = 0
	
	if inc != 0 and size > 1:
		match loop:
			LoopType.LOOP:
				i = (i + (_direction * inc)) % size
			LoopType.NONE:
				i += _direction * inc
			LoopType.PINGPONG:
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

		set_active_index(i)
#		if active_flags == 0:
#			current_index = i
#		else:
#			current_f_index = i
#			current_index = filtered_indices[current_f_index]

	return values[current_index]
