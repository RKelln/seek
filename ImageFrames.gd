extends SpriteFrames

class_name ImageFrames

@export var base_animation_name : String = "default"
@export var compress := true
@export var pack_name : String = ""
@export var stretch := true

var version := "1.0"

func get_total_frame_count() -> int:
	var count := 0
	for anim in get_animation_names():
		count += get_frame_count(anim)
	return count


func get_frame_counts() -> Dictionary:
	var counts = {}
	for anim in get_animation_names():
		counts[anim] = get_frame_count(anim)
	return counts


func info() -> Dictionary:
	return {
		'pack_name' : pack_name,
		'frames': get_total_frame_count(),
		'sequences': get_animation_names(),
		'frame_counts': get_frame_counts(),
	}
