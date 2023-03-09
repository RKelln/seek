extends CustomController

var midi_min_value := 0.0
var midi_max_value := 127.0

# AKAI AOC40 MK II

# knobs along top, left to right
const knob_top_1 := { 'channel': 0, 'message': 11, 'controller': 48 }
const knob_top_2 := { 'channel': 0, 'message': 11, 'controller': 49 }
const knob_top_3 := { 'channel': 0, 'message': 11, 'controller': 50 }
const knob_top_4 := { 'channel': 0, 'message': 11, 'controller': 51 }
const knob_top_5 := { 'channel': 0, 'message': 11, 'controller': 52 }
const knob_top_6 := { 'channel': 0, 'message': 11, 'controller': 53 }
const knob_top_7 := { 'channel': 0, 'message': 11, 'controller': 54 }
const knob_top_8 := { 'channel': 0, 'message': 11, 'controller': 55 }

# knobs on middle right
const knob_right_1 := { 'channel': 0, 'message': 11, 'controller': 16 }
const knob_right_2 := { 'channel': 0, 'message': 11, 'controller': 17 }
const knob_right_3 := { 'channel': 0, 'message': 11, 'controller': 18 }
const knob_right_4 := { 'channel': 0, 'message': 11, 'controller': 19 }
const knob_right_5 := { 'channel': 0, 'message': 11, 'controller': 20 }
const knob_right_6 := { 'channel': 0, 'message': 11, 'controller': 21 }
const knob_right_7 := { 'channel': 0, 'message': 11, 'controller': 22 }
const knob_right_8 := { 'channel': 0, 'message': 11, 'controller': 23 }

# left to right along the bottom
const fader_1 := { 'channel': 0, 'message': 11, 'controller': 7 }
const fader_2 := { 'channel': 1, 'message': 11, 'controller': 7 }
const fader_3 := { 'channel': 2, 'message': 11, 'controller': 7 }
const fader_4 := { 'channel': 3, 'message': 11, 'controller': 7 }
const fader_5 := { 'channel': 4, 'message': 11, 'controller': 7 }
const fader_6 := { 'channel': 5, 'message': 11, 'controller': 7 }
const fader_7 := { 'channel': 6, 'message': 11, 'controller': 7 }
const fader_8 := { 'channel': 7, 'message': 11, 'controller': 7 }
const fader_master := { 'channel': 0, 'message': 11, 'controller': 14 }


# Called when the node enters the scene tree for the first time.
func _ready():
	OS.open_midi_inputs()
	print("Connect to midi")
	print(OS.get_connected_midi_inputs())


func _handle_input(event : InputEvent) -> void:
	
	if not event is InputEventMIDI: return
	
#	if mode == Mode.TEST:
#		_print_midi_info(event)
	
	_print_midi_info(event)

	var ev = InputEventTargetedAction.new()
	ev.pressed = true
	
	var m = {'channel': event.channel, 'message': event.message}
	
	if event.controller_number > 0:
		m['controller'] = event.controller_number
		ev.strength = event.controller_value / midi_max_value
		
		match m:
			knob_top_1:
				ev.action = "set_speed"
				ev.target = 0
			knob_top_2:
				ev.action = "set_speed"
				ev.target = 1
			knob_top_3:
				ev.action = "set_speed"
				ev.target = 2
			knob_right_1:
				ev.action = "set_transition_duration"
				ev.target = 0
			knob_right_2:
				ev.action = "set_transition_duration"
				ev.target = 1
			knob_right_3:
				ev.action = "set_transition_duration"
				ev.target = 2
			fader_1:
				ev.action = "set_opacity"
				ev.target = 0
			fader_2:
				ev.action = "set_opacity"
				ev.target = 1
			fader_3:
				ev.action = "set_opacity"
				ev.target = 2

	if event.message == 9 or event.message == 8:
		m['pitch'] = event.pitch
		if event.message == 8:
			ev.pressed = true
		elif event.message == 9:
			ev.pressed = false
		# TEST: send tag and map pitch to tag
		ev.action = "set_flag"
		ev.target = 1 << int(event.pitch)

	Input.parse_input_event(ev)


func _print_midi_info(midi_event: InputEventMIDI):
	print(midi_event)
#	print("Channel " + str(midi_event.channel))
#	print("Message " + str(midi_event.message))
#	print("Pitch " + str(midi_event.pitch))
#	print("Velocity " + str(midi_event.velocity))
#	print("Instrument " + str(midi_event.instrument))
#	print("Pressure " + str(midi_event.pressure))
#	print("Controller number: " + str(midi_event.controller_number))
#	print("Controller value: " + str(midi_event.controller_value))
