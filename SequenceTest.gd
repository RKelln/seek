extends Node2D

const Sequence = preload("res://Sequence.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	test_iterator()
	test_filtered_values()
	test_filtered_performance()
	test_iterator_performance()
	print("success!")


func test_iterator():
	var s : Sequence = Sequence.new()
	var test_frames = PackedInt32Array([0,1,2,3,4,5])
	s.values.append_array(test_frames)
	assert(s.next() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)
	assert(s.next() == 3)
	assert(s.next() == 4)
	assert(s.next() == 5)
	assert(s.next() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)
	s.loop = Sequence.LOOP_TYPE.NONE
	assert(s.next() == 3)
	assert(s.next() == 4)
	assert(s.next() == 5)
	assert(s.next() == 5)
	assert(s.next() == 5)
	s.loop = Sequence.LOOP_TYPE.PINGPONG
	assert(s.next() == 4)
	assert(s.next() == 3)
	assert(s.next() == 2)
	assert(s.next() == 1)
	assert(s.next() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)


func test_filtered_values():
	var s : Sequence = Sequence.new()
	var test_frames = PackedInt32Array([0,1,2,3,4,5])
	s.values.append_array(test_frames)
	var test_flags = PackedByteArray([0b00000000,0b00000001,0b00000011,0b00000111,0b00001111,0b11111111])
	s.flags.append_array(test_flags)
	var filtered : PackedInt32Array
	s.filter_values(0b00000000)
	assert(s.filtered_values.size() == 6)
	s.filter_values(0b00000001)
	assert(s.filtered_values == PackedInt32Array([1,2,3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	assert(s.filtered_values == PackedInt32Array([2,3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F3)
	assert(s.filtered_values == PackedInt32Array([3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F4 | Sequence.BIT_FLAGS.F1)
	assert(s.filtered_values == PackedInt32Array([4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F8)
	assert(s.filtered_values == PackedInt32Array([5]))

func test_filtered_performance():
	var s : Sequence = Sequence.new()
	var size := 1
	for i in size:
		s.values.append(randi())
		s.flags.append(randi())
	
	var now = Time.get_ticks_usec()
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	var dur = Time.get_ticks_usec() - now
	printt(size, "duration (usec)", dur, "ms:", dur / 1000)
	
	s = Sequence.new()
	size = 100000
	for i in size:
		s.values.append(randi())
		s.flags.append(randi())
	
	now = Time.get_ticks_usec()
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	dur = Time.get_ticks_usec() - now
	printt("filter perf", size, "duration (usec)", dur, "ms:", dur / 1000)


func test_iterator_performance():
	var s : Sequence = Sequence.new()
	var size := 1
	var iterations := 50
	for i in size:
		s.values.append(randi())
	
	var now = Time.get_ticks_usec()
	for i in iterations:
		s.next()
	var dur = Time.get_ticks_usec() - now
	printt("iterator perf", size, iterations, "duration (usec)", dur, "ms:", dur / 1000)

	s = Sequence.new()
	size = 10000
	iterations = 50
	for i in size:
		s.values.append(randi())
	now = Time.get_ticks_usec()
	for i in iterations:
		s.next()
	dur = Time.get_ticks_usec() - now
	printt("iterator perf", size, iterations, "duration (usec)", dur, "ms:", dur / 1000)
	
	iterations = 100000
	now = Time.get_ticks_usec()
	for i in iterations:
		s.next()
	dur = Time.get_ticks_usec() - now
	printt("iterator perf", size, iterations, "duration (usec)", dur, "ms:", dur / 1000)
