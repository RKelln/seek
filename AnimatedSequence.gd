class_name AnimatedSequence extends Sequence

# Sequence with an associated animation name

var animation : StringName
var frame_count : int

func _init(initial_values: Variant, animation_name : StringName, frame_count: int, 
	flags : Variant = [], loop_type := Sequence.LoopType.LOOP
	) -> void:
	super(initial_values, flags, loop_type)
	self.animation = animation_name
	self.frame_count = frame_count


func get_frame_texture(frames : SpriteFrames, index : int = -1) -> Texture2D:
	if index == -1: index = current_index
	return frames.get_frame_texture(animation, index)


static func from_Sequence(seq : Sequence, animation : StringName,
	loop_type := Sequence.LoopType.LOOP
	) -> AnimatedSequence:
	var aseq := AnimatedSequence.new(seq.values, animation, seq.size(), seq.flags, loop_type)
	if is_instance_valid(seq.mapping):
		aseq.set_mapping(seq.mapping)
	return aseq
