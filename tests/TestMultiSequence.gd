extends Node


func _ready():
	test_iterator()
	test_filtered_values()
	test_filtered_iteration()
	print("AnimatedMultiSequence test success!")


func test_iterator():
	# animation : StringName, frame_count: int, sub_sequences : Array, loop_type := Sequence.LoopType.LOOP, mode := Mode.CHOOSE_ONE
	var next : int
	var sub_sequences : Array[Sequence] = [Sequence.new(1)]
	var s : AnimatedMultiSequence = AnimatedMultiSequence.new(1, "test", 1, sub_sequences)
	assert(s.current_value() == 0)
	assert(s.next() == 0)
	assert(s.next() == 0)
	
	# CHOOSE_ONE
	sub_sequences = [Sequence.new([0,0,0]), Sequence.new([1,1,1]), Sequence.new([2,2,2])]
	s = AnimatedMultiSequence.new(3, "test", 3, sub_sequences, [], Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.CHOOSE_ONE)
	assert(s.current_value() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)
	assert(s.next() == 0)
	
	# PLAY_THROUGH
	sub_sequences = [Sequence.new([1,2,0]), Sequence.new([0,2,1]), Sequence.new([2,1,0])]
	s = AnimatedMultiSequence.new(3, "test", 3, sub_sequences, [], Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.PLAY_THROUGH)
	assert(s.current_value() == 1)
	next = s.next()
	assert(next == 2, "got %d, expected 2" % next)
	next = s.next()
	assert(next == 0, "got %d, expected 0" % next)
	assert(s.next() == 0)
	assert(s.next() == 2)
	assert(s.next() == 1)
	assert(s.next() == 2)
	assert(s.next() == 1)
	assert(s.next() == 0)
	assert(s.next() == 1)
	assert(s.next() == 2)
	assert(s.next() == 0)
	assert(s.next() == 0)
	
	# NEIGHBOURS
	sub_sequences = [Sequence.new([1,2]), Sequence.new([2,0]), Sequence.new([0,1])]
	s = AnimatedMultiSequence.new([4,5,6], "test", 7, sub_sequences, [], Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.NEIGHBOURS)
	assert(s.current_value() == 4) # start with index 0
	next = s.next() # then find index 0's closest neighbour: index 1
	assert(next == 5, "got %d, expected 5" % next)
	next = s.next()
	assert(next == 6, "got %d, expected 6" % next)
	next = s.next()
	assert(next == 4, "got %d, expected 4" % next)
	next = s.next()
	assert(next == 6, "got %d, expected 6" % next)
	assert(s.next() == 5)
	assert(s.next() == 4)
	# cycle complete, but index 1 selected more often, so select index 2
	next = s.next()
	assert(next == 6, "got %d, expected 6" % next)
	assert(s.next() == 5)
	assert(s.next() == 4)
	assert(s.next() == 6)
	assert(s.next() == 5)
	assert(s.next() == 4)
	
	
func test_filtered_values():
	var test_flags = PackedInt64Array([0,Sequence.BitFlags.F1, Sequence.BitFlags.F1 | Sequence.BitFlags.F2])
	var sub_sequences : Array[Sequence] = [Sequence.new([1,2]), Sequence.new([2,0]), Sequence.new([0,1])]
	var s := AnimatedMultiSequence.new([4,5,6], "test", 7, sub_sequences, test_flags, Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.NEIGHBOURS)
	
	s.filter_values(0)
	assert(s.get_filtered_values().size() == 3)
	s.filter_values(Sequence.BitFlags.F1)
	assert(s.get_filtered_values() == PackedInt32Array([5,6]))
	s.filter_values(Sequence.BitFlags.F1 | Sequence.BitFlags.F2)
	assert(s.get_filtered_values() == PackedInt32Array([6]))
	
	s.active_flags = Sequence.BitFlags.F1
	assert(s.get_filtered_values() == PackedInt32Array([5,6]))
	s.active_flags = Sequence.BitFlags.F2
	assert(s.get_filtered_values() == PackedInt32Array([6]))


func test_filtered_iteration():
	var test_flags = PackedInt64Array([0,Sequence.BitFlags.F1, Sequence.BitFlags.F1 | Sequence.BitFlags.F2])
	var sub_sequences : Array[Sequence] = [Sequence.new([1,2]), Sequence.new([2,0]), Sequence.new([0,1])]
	var s := AnimatedMultiSequence.new([4,5,6], "test", 7, sub_sequences, test_flags, Sequence.LoopType.LOOP, AnimatedMultiSequence.Mode.NEIGHBOURS)
	var next : int 
	
	assert(s.current_value() == 4)
	assert(s.next() == 5)
	assert(s.next() == 6)
	s.active_flags = 1
	assert(s.get_filtered_values() == PackedInt32Array([5,6]))
	assert(s.sub_sequences[0].get_filtered_values() == PackedInt32Array([1,2]))
	assert(s.sub_sequences[1].get_filtered_values() == PackedInt32Array([2]))
	assert(s.sub_sequences[2].get_filtered_values() == PackedInt32Array([1]))
	# doesn't change current_value
	assert(s.current_value() == 6)
	next = s.next()
	assert(next == 5, "got %d, expected 5" % next)  # not 4, because it is filtered now
	assert(s.next() == 6)
	assert(s.next() == 5)
	
	s.active_flags = 0
	assert(s.current_value() == 5)
	next = s.next()
	assert(next == 4, "got %d, expected 6" % next)
	next = s.next()
	assert(next == 6, "got %d, expected 5" % next)
	
#	assert(s.next() == 5)
#	assert(s.next() == 1)
#	assert(s.next() == 2)
#	assert(s.next() == 3)
#	s.active_flags = 0
#	assert(s.current_value() == 3)
#	assert(s.next() == 4)
#	s.active_flags = 1
#	assert(s.current_value() == 4)
#	# should retain position as best it can
#	assert(s.next() == 5)
#	s.loop = Sequence.LoopType.PINGPONG
#	assert(s.next() == 3)
#	assert(s.next() == 2)
#	assert(s.next() == 1)
#	assert(s.next() == 2)
#	s.active_flags = 0
#	assert(s.current_value() == 2)
#	assert(s.next() == 3)
#	assert(s.next() == 4)
	
