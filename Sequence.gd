class_name Sequence extends Resource

# Simple Sequence

# A sequence that stores ints in order. Each int also has a bitflag that can be used for masking.

var values := PackedInt32Array()
var flags := PackedInt64Array()
var filtered_values : PackedInt32Array 

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

var current_index := 0
var active_flags := 0

enum LOOP_TYPE {NONE, LOOP, PINGPONG}
var loop := LOOP_TYPE.LOOP
var _direction : int = 1

class ForwardIterator:
	var start : int
	var current : int
	var end : int

	func _init(start, stop):
		self.start = start
		self.current = start
		self.end = stop

	func finished():
		return current >= end

	func reset():
		current = start
		
	func next():
		if finished():
			return end 
		else:
			_iter_next

	func _iter_init(arg):
		reset()
		return not finished()

	func _iter_next(arg):
		current += 1
		return not finished()

	func _iter_get(arg):
		return current


class LoopIterator:
	var start : int
	var current : int
	var size : int
	var looped : bool

	func _init(start : int, size : int):
		self.start = start
		self.current = start
		self.size = size
		self.looped = false

	func finished():
		return looped && current == start

	func reset():
		current = start
		looped = false
		
	func _iter_init(arg):
		reset()
		return not finished()

	func _iter_next(arg):
		current += 1
		if current >= size:
			looped = true
			current = 0
		return not finished()

	func _iter_get(arg):
		return current


class PingPongIterator:
	var start
	var end
	var current
	var size
	var complete_cycle
	var dir
	var start_dir

	func _init(start : int, size : int, dir : int = 1):
		self.start = start
		self.current = start
		self.size = size
		self.complete_cycle = false
		self.start_dir = dir
		self.dir = dir

	func finished():
		return complete_cycle && current == end

	func reset():
		current = start
		dir = start_dir
		# if we start at the beginning or end, then no pingpong
		# only 1 time through (i.e. see every index at least once)
		if current == 0:
			end = size - 1
			complete_cycle = true
		elif current == size -1:
			end = 0
			complete_cycle = true
		else:
			end = start
			complete_cycle = false

	func _iter_init(arg):
		reset()
		return not finished()

	func _iter_next(arg):
		if current <= 0:
			dir = 1
			complete_cycle = true
		elif current >= size - 1:
			dir = -1
			complete_cycle = true
		current += dir
		return not finished()

	func _iter_get(arg):
		return current


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


func filter_values(bitmask : int = 0):
	filtered_values.clear()
	for i in values.size():
		if bitmask & flags[i] == bitmask:
			filtered_values.append(values[i])


func get_values() -> PackedInt32Array:
	if active_flags > 0:
		return filtered_values
	return values


func max_value() -> int:
	return Array(values).max()


func min_value() -> int:
	return Array(values).min()


func next(inc : int = 1) -> int:
	var v := get_values()

	if inc > 0 and v.size() > 1:
		match loop:
			LOOP_TYPE.LOOP:
				current_index = (current_index + (_direction * inc)) % v.size()
			LOOP_TYPE.NONE:
				current_index += _direction * inc
			LOOP_TYPE.PINGPONG:
				var steps : int = abs(inc)
				while steps > 0:
					steps -= 1
					current_index += _direction
					if current_index < 0:
						_direction = -_direction
						current_index = 1 # one from start
					elif current_index >= v.size():
						_direction = -_direction
						current_index = v.size() - 2 # one from end
	
	current_index = clampi(current_index, 0, v.size() - 1)
	
	return v[current_index]


func get_iterator(type : LOOP_TYPE):
	match loop:
		LOOP_TYPE.LOOP:
			return LoopIterator.new(current_index, values.size())
		LOOP_TYPE.NONE:
			return ForwardIterator.new(current_index, values.size())
		LOOP_TYPE.PINGPONG:
			return PingPongIterator.new(current_index, values.size())

