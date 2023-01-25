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

	var m = {'channel': event.channel, 'message': event.message, 'controller': event.controller_number}
	
	match m:
		knob_top_1:
			change_speed.emit(event.controller_value / midi_max_value, 0)
			
		knob_top_2:
			change_speed.emit(event.controller_value / midi_max_value, 1)
		
		knob_top_3:
			change_speed.emit(event.controller_value / midi_max_value, 2)
		
		fader_1:
			fade.emit(event.controller_value / midi_max_value, 0)
			
		fader_2:
			fade.emit(event.controller_value / midi_max_value, 1)
			
		fader_3:
			fade.emit(event.controller_value / midi_max_value, 2)


func _print_midi_info(midi_event: InputEventMIDI):
	print(midi_event)
	print("Channel " + str(midi_event.channel))
	print("Message " + str(midi_event.message))
	print("Pitch " + str(midi_event.pitch))
	print("Velocity " + str(midi_event.velocity))
	print("Instrument " + str(midi_event.instrument))
	print("Pressure " + str(midi_event.pressure))
	print("Controller number: " + str(midi_event.controller_number))
	print("Controller value: " + str(midi_event.controller_value))
