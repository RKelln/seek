class_name TagFlagKeyMap extends Object

## 3 way mapping between string tag, bitmask flag, and keycode

var _tags : Array[String]
var _flags : PackedInt64Array
var _keys : Array[int]
var _tags_map : Dictionary
var _flags_map : Dictionary
var _keys_map : Dictionary

func _init(tags : Array[String], flags : PackedInt64Array, keys : Array[int]):
	_tags = tags
	_flags = flags
	_keys = keys
	
	assert(tags.size() == flags.size())
	assert(tags.size() == keys.size())

	var i : int = 0
	for t in _tags:
		_tags_map[t] = i
		i += 1
	i = 0
	for f in _flags:
		_flags_map[f] = i
		i += 1
	i = 0
	for k in _keys:
		_keys_map[k] = i
		i += 1


func _to_string():
	for tag in _tags:
		prints(tag, "=", OS.get_keycode_string(tag_key(tag)), " [", tag_flag(tag), "]")


func size():
	return _tags.size()


func tag_flag(tag : String) -> int:
	return _flags[_tags_map[tag]]

func tag_key(tag : String) -> int:
	return _keys[_tags_map[tag]]


func key_flag(key : int) -> int:
	return _flags[_keys_map[key]]
	
func key_tag(key : int) -> String:
	return _tags[_keys_map[key]]


func flag_tag(flag : int) -> String:
	return _tags[_flags_map[flag]]

func flag_key(flag : int) -> int:
	return _keys[_flags_map[flag]]


func tag_exists(tag : String) -> bool:
	return tag in _tags_map

func key_exists(key : int) -> bool:
	return key in _keys_map
	
func flag_exists(flag : int) -> bool:
	return flag in _flags_map


func flags_to_tags(flags : int, active_flags : int = 0) -> String:
	var tags = []
	for flag in _flags:
		if flags & flag != 0:
			var tag = _tags[_flags_map[flag]]
			if flag & active_flags != 0:
				tag = tag.to_upper()
			tags.append(tag)
	tags.sort()
	var s := ""
	for t in tags:
		s += t + ", "
	return s.trim_suffix(", ")
