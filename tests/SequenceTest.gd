extends Node2D

const Sequence = preload("res://Sequence.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	test_iterator()
	test_filtered_values()
	test_filtered_performance()
	test_filtered_iteration()
	test_iterator_performance()
	print("success!")


func test_iterator():
	var s : Sequence = Sequence.new(6)
	assert(s.current_value() == 0)
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
	
	assert(s.next(-1) == 1)
	assert(s.next(-1) == 0)
	assert(s.next(-2) == 2)
	
	


func test_filtered_values():
	var s : Sequence = Sequence.new(6)
	var test_flags = PackedInt64Array([0,1,3,7,15,
		Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2 | Sequence.BIT_FLAGS.F3 | Sequence.BIT_FLAGS.F4 |
		Sequence.BIT_FLAGS.F5 | Sequence.BIT_FLAGS.F6 | Sequence.BIT_FLAGS.F7 | Sequence.BIT_FLAGS.F8])
	s.flags.append_array(test_flags)

	s.filter_values(0)
	assert(s.get_filtered_values().size() == 6)
	s.filter_values(1)
	assert(s.get_filtered_values() == PackedInt32Array([1,2,3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	assert(s.get_filtered_values() == PackedInt32Array([2,3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F3)
	assert(s.get_filtered_values() == PackedInt32Array([3,4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F4 | Sequence.BIT_FLAGS.F1)
	assert(s.get_filtered_values() == PackedInt32Array([4,5]))
	s.filter_values(Sequence.BIT_FLAGS.F8)
	assert(s.get_filtered_values() == PackedInt32Array([5]))
	
	s.active_flags = 1
	assert(s.get_filtered_values() == PackedInt32Array([1,2,3,4,5]))
	s.active_flags = Sequence.BIT_FLAGS.F8
	assert(s.get_filtered_values() == PackedInt32Array([5]))


func test_filtered_performance():
	var size := 1
	var s : Sequence = Sequence.new(size)
	for i in size:

		s.flags.append(randi())
	
	var now = Time.get_ticks_usec()
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	var dur = Time.get_ticks_usec() - now
	printt(size, "duration (usec)", dur, "ms:", dur / 1000)
	
	size = 100000
	s = Sequence.new(size)
	for i in size:
		s.flags.append(randi())
	
	now = Time.get_ticks_usec()
	s.filter_values(Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2)
	dur = Time.get_ticks_usec() - now
	printt("filter perf", size, "duration (usec)", dur, "ms:", dur / 1000)


func test_filtered_iteration():
	var s : Sequence = Sequence.new(6)
	var test_flags = PackedInt64Array([0,1,3,7,2,
		Sequence.BIT_FLAGS.F1 | Sequence.BIT_FLAGS.F2 | Sequence.BIT_FLAGS.F3 | Sequence.BIT_FLAGS.F4 |
		Sequence.BIT_FLAGS.F5 | Sequence.BIT_FLAGS.F6 | Sequence.BIT_FLAGS.F7 | Sequence.BIT_FLAGS.F8])
	s.flags.append_array(test_flags)

	assert(s.current_value() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)
	s.active_flags = 1
	assert(s.get_filtered_values() == PackedInt32Array([1,2,3,5]))
	# doesn't change current_value
	assert(s.current_value() == 2)
	assert(s.next() == 3)
	assert(s.next() == 5)
	assert(s.next() == 1)
	assert(s.next() == 2)
	assert(s.next() == 3)
	s.active_flags = 0
	assert(s.current_value() == 3)
	assert(s.next() == 4)
	s.active_flags = 1
	assert(s.current_value() == 4)
	# should retain position as best it can
	assert(s.next() == 5)
	s.loop = Sequence.LOOP_TYPE.PINGPONG
	assert(s.next() == 3)
	assert(s.next() == 2)
	assert(s.next() == 1)
	assert(s.next() == 2)
	s.active_flags = 0
	assert(s.current_value() == 2)
	assert(s.next() == 3)
	assert(s.next() == 4)
	

func test_iterator_performance():
	var size := 1
	var s : Sequence = Sequence.new(size)
	var iterations := 50
	for i in size:
		s.values.append(randi())
	
	var now = Time.get_ticks_usec()
	for i in iterations:
		s.next()
	var dur = Time.get_ticks_usec() - now
	printt("iterator perf", size, iterations, "duration (usec)", dur, "ms:", dur / 1000)

	size = 10000
	iterations = 50
	s = Sequence.new(size)
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
