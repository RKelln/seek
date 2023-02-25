class_name AnimatedSequence extends Sequence

# Sequence with an associated animation name

var animation : StringName


func _init(initial_values: Variant, animation : StringName, frame_count: int, loop_type := Sequence.LOOP_TYPE.LOOP) -> void:
	super(initial_values, loop_type)
	self.animation = animation

	# none of the values that refer to frame numbers can be more than the frame count
	assert(max_value() < frame_count)


func get_frame_texture(frames : SpriteFrames, index : int = -1) -> Texture2D:
	if index == -1: index = current_index
	return frames.get_frame_texture(animation, index)
