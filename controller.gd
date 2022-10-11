extends Node

enum Mode {SKIP, SPEED, TEST}

const knob_clockwise := KEY_HOME
const knob_cclockwise := KEY_END

const knob1_clockwise := KEY_EQUAL
const knob1_cclockwise := KEY_MINUS
const knob2_clockwise := KEY_BRACKETLEFT
const knob2_cclockwise := KEY_BRACKETRIGHT
const knob3_clockwise := KEY_PAGEUP
const knob3_cclockwise := KEY_PAGEDOWN

const btn_tl := KEY_KP_7
const btn_t := KEY_KP_8
const btn_tr := KEY_KP_9
const btn_l := KEY_KP_4
const btn_c := KEY_KP_5
const btn_r := KEY_KP_6
const btn_bl := KEY_KP_1
const btn_b := KEY_KP_2
const btn_br := KEY_KP_3

@export var mode : Mode = Mode.TEST
@export var sensitivity : float = 1.0

signal skip_frame(value : float)
signal change_speed(value : float)
signal fade(value : float)
signal pause
signal reverse
signal change_animation(value : int)
signal beat

var speed : float = 0
const max_speed := 50

var fade_amount : float = 0.05


func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
 
	var info := {}
	
	match mode:
		Mode.TEST:
			print(event)
			match event.keycode:
				knob_clockwise:
					print("knob_clockwise")
				knob_cclockwise:
					print("knob_cclockwise")

				knob1_clockwise:
					print("knob1_clockwise")
				knob1_cclockwise:
					print("knob1_cclockwise")
				knob2_clockwise:
					print("knob2_clockwise")
				knob2_cclockwise:
					print("knob2_cclockwise")
				knob3_clockwise:
					print("knob3_clockwise")
				knob3_cclockwise:
					print("knob3_cclockwise")

				btn_tl:
					print("btn_tl")
				btn_t:
					print("btn_t")
				btn_tr:
					print("btn_tr")
				btn_l:
					print("btn_l")
				btn_c:
					print("btn_c")
				btn_r:
					print("btn_r")
				btn_bl:
					print("btn_bl")
				btn_b:
					print("btn_b")
				btn_br:
					print("btn_br")
				_:
					print("Unmapped key: ", event.keycode, event)
					
		Mode.SKIP:
			match event.keycode:
				knob_clockwise:
					skip_frame.emit(sensitivity)
					info['skip_frame'] = 1
				knob_cclockwise:
					skip_frame.emit(-sensitivity)
					info['skip_frame'] = -1
					
				knob1_clockwise:
					#speed = linear_to_relative(speed, 1, -max_speed, max_speed, change_speed, -1.0)
					change_speed.emit(1)
					info['speed'] = speed
				knob1_cclockwise:
					#speed = linear_to_relative(speed, -1, -max_speed, max_speed, change_speed, -1.0)
					change_speed.emit(-1)
					info['speed'] = speed
				
				# change animation (NOTE: knob not working)
				knob2_clockwise:
					change_animation.emit(1)
					info['change_animation'] = 1
				knob2_cclockwise:
					change_animation.emit(-1)
					info['change_animation'] = -1
				
				# fade
				knob3_clockwise:
					fade.emit(fade_amount)
					info['fade'] = fade_amount
				knob3_cclockwise:
					fade.emit(-fade_amount)
					info['fade'] = -fade_amount
				
				# pause / reverse
				btn_c:
					if event.pressed:
						pause.emit()
						info['pause'] = true
					else:
						reverse.emit()
						info['reverse'] = true
				
				# jump forward/back
				btn_l:
					if event.pressed and not event.is_echo():
						skip_frame.emit(-6)
						info['skip_frame'] = -6
				btn_r:
					if event.pressed and not event.is_echo():
						skip_frame.emit(3)
						info['skip_frame'] = 3
				
				# change animation
				btn_tr:
					if not event.pressed:
						change_animation.emit(1)
						info['change_animation'] = 1
				btn_tl:
					if not event.pressed:
						change_animation.emit(-1)
						info['change_animation'] = -1
				# beat match
				btn_t:
					if event.pressed and not event.is_echo():
						beat.emit()
						info['beat'] = true
				
		Mode.SPEED:
			match event.keycode:
				knob_clockwise:
					speed = clampi(speed + 1, -max_speed, max_speed)
					change_speed.emit( remap(speed, -max_speed, max_speed, -1.0, 1.0) )
					info['speed'] = speed
				knob_cclockwise:
					speed = clampi(speed - 1, -max_speed, max_speed)
					change_speed.emit( remap(speed, -max_speed, max_speed, -1.0, 1.0) )
					info['speed'] = speed
	
#	if not event.pressed: # key released
#		if event.keycode == btn_tl:
#			while mode != Mode.TEST:
#				mode = int(fposmod(mode + 1, Mode.size()))
#
#			info['mode'] = mode
			
	printt("mode:", mode, "key:", event.keycode, info)


func linear_to_relative(value : float, increment : float, vmin : float, vmax : float, emit_signal : Signal, out_min : float = 0.0, out_max : float = 1.0) -> float:
	value = clampf(value + (increment * sensitivity), vmin, vmax)
	emit_signal.emit( remap(value, vmin, vmax, out_min, out_max) )
	return value
