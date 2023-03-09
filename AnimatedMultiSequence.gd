class_name AnimatedMultiSequence extends AnimatedSequence

# Animated sequence composed of sub-Sequences
# Initial data is an Array of Array of ints (indexes to initial values)

const MAX_TRIES := 10

# CHOOSE_ONE: choose randomly from subsequence, 
# PLAY_THROUGH: iterate through subsequence then move to next subsequence
# NEIGHBOURS: subsequences are sorted neighbours list, pick closest
enum Mode {CHOOSE_ONE, PLAY_THROUGH, NEIGHBOURS}
var mode := Mode.CHOOSE_ONE : set = set_mode

# subsequences contain indices to values
var sub_sequences : Array[Sequence]
var allow_repeats := false  # iterate through all values before repeating any

var _display_counts := PackedInt32Array()


static func from_AnimatedSequence(aseq : AnimatedSequence, sub_sequences : Array, 
	loop_type := Sequence.LoopType.LOOP, mode := Mode.CHOOSE_ONE
	) -> AnimatedMultiSequence:
	return AnimatedMultiSequence.new(
		aseq.values, aseq.animation, aseq.frame_count, 
		sub_sequences, aseq.flags, loop_type, mode)


func _init(initial_values: Variant, animation : StringName, frame_count: int, sub_sequences : Array, 
	flags : Variant = [], loop_type := Sequence.LoopType.LOOP, mode := Mode.CHOOSE_ONE
	) -> void:
		
	assert(sub_sequences is Array)
	assert(sub_sequences.size() > 0)
	# none of the values that refer to frame numbers can be more than the frame count
	for s in sub_sequences:
		assert(s is Sequence)
		assert(s.max_value() < frame_count)
		
	self.sub_sequences = sub_sequences
	self.mode = mode
	# importnat that properties are set first before parent class
	super(initial_values, animation, frame_count, flags, loop_type)

	_display_counts.resize(values.size())
	_display_counts[current_index] += 1  # we start displaying the current index


func set_flags(f : Variant):	
	if flags is PackedInt64Array:
		flags = f
	else:
		flags = PackedInt64Array(f)
	if flags.size() != values.size():
		if flags.size() > 0:
			print("Warning: size of flags ({0}) does not match size of values ({1})".format([flags.size(), values.size()]))
		flags.resize(values.size())
		
	# Because the sub-squences contain value indices, their flags have to be adjusted
	# to match the flag of the index
	for s in sub_sequences:
		var sub_flags := PackedInt64Array()
		for value_index in s.values:
			sub_flags.append(flags[value_index])
		s.flags = sub_flags


func set_active_flags(bitmask : int) -> void:
	super(bitmask)
	for s in sub_sequences:
		s.active_flags = bitmask


func set_mode(new_mode : Mode) -> void:
	mode = new_mode
	if mode == Mode.PLAY_THROUGH:
		for s in sub_sequences:
			s.loop = Sequence.LoopType.NONE

#func filter_values(bitmask : int = 0) -> void:
#	super(bitmask)
#	sub_sequences[current_index].filter_values(bitmask)


func current_value() -> int:
	assert(current_index >= 0)
	if mode == Mode.NEIGHBOURS:
		return values[current_index]
	else:
		return values[sub_sequences[current_index].value()]


func next(inc : int = 1) -> int:
	var i : int = current_index
	match mode:
		Mode.CHOOSE_ONE:
			super(inc) # changes current_index
			# TODO: do not repeat
			var rand_i : int = randi() % sub_sequences[current_index].get_active_size()
			i = sub_sequences[current_index].set_active_index(rand_i)

		Mode.PLAY_THROUGH:
			# NOTE: sub-sequences must be LoopType NONE (i.e. stop at the ends)
			# TODO: change to listen/poll for finished cycle
			var remaining_inc := inc
			var orig_sub_i : int
			if inc != 0:
				while abs(remaining_inc) > 0:
					orig_sub_i = sub_sequences[current_index].current_index
					i = sub_sequences[current_index].next(remaining_inc)
					if inc > 0:
						remaining_inc -= sub_sequences[current_index].current_index - orig_sub_i
					else:
						remaining_inc += orig_sub_i - sub_sequences[current_index].current_index	
					#prints("sub:", sub_sequences[current_index].current_index, "+", inc, "of", sub_sequences[current_index].size(), "=", remaining_inc)
					if abs(remaining_inc) > 0:
						sub_sequences[current_index].current_index = 0 # reset the sub sequence
						super.next(sign(inc)) # advance to next sequence
						i = sub_sequences[current_index].value()
						remaining_inc -= sign(inc) # count that step in remaining steps to do

		Mode.NEIGHBOURS:
			# NOTE: only advances by 1 frame!
			# init with current 
			var s : Sequence = sub_sequences[current_index]
			s.filter_current_index()
			var start_index := s.current_value()
			var next_index := s.next(sign(inc)) 
			var start_count := _display_counts[start_index]
			var next_count := _display_counts[next_index]
			var attempts := 0
			var max_attempts : int = mini(MAX_TRIES, s.get_active_size())
			if start_count == 0:
				# haven't displayed the first value yet, use it
				i = start_index
			else:
				while ((current_index == next_index or next_count >= start_count)
					and attempts < max_attempts 
					and start_index != next_index):
					next_index = s.next(sign(inc))
					next_count = _display_counts[next_index]
					attempts += 1
				i = next_index
			current_index = i
	
	_display_counts[i] += 1
	return current_value()

