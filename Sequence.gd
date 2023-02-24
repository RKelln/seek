extends Resource

# Simple Sequence

# A sequence that stores ints in order. Each int also has a int flag that can be used for masking.

signal cycle_completed

var values := PackedInt32Array()
var filtered_values : PackedInt32Array 
var flags := PackedByteArray()

enum BIT_FLAGS { 
	NONE = 0, 
	F1 = 0b00000001,
	F2 = 0b00000010,
	F3 = 0b00000100,
	F4 = 0b00001000,
	F5 = 0b00010000,
	F6 = 0b00100000,
	F7 = 0b01000000,
	F8 = 0b10000000,
}

var current_index := -1
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


func _init() -> void:
	loop = LOOP_TYPE.LOOP


func value(i : int = -1) -> int:
	if i == -1: i = current_index
	return values[i]


func flag(i : int = -1) -> int:
	if i == -1: i = current_index
	return flags.decode_u8(i)


func filter_values(bitmask := 0b0):
	filtered_values.clear()
	for i in values.size():
		if bitmask & flags.decode_u8(i) == bitmask:
			filtered_values.append(values[i])


func get_values() -> PackedInt32Array:
	if active_flags > 0:
		return filtered_values
	return values


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

