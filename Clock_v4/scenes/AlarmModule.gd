extends PanelContainer

enum AlarmStatus {SET, OFF, PREP, ACTIVATED}
export(AlarmStatus) var alarm_status = AlarmStatus.OFF setget set_alarm_status

onready var _minute_alarm_slider = $MarginContainer/VBoxContainer/SliderHBox/SliderBars/MinAlarmSlider
onready var _hour_alarm_slider = $MarginContainer/VBoxContainer/SliderHBox/SliderBars/HrAlarmSlider
onready var _min_slider_info = $MarginContainer/VBoxContainer/SliderHBox/SliderInfo/AlarmMins
onready var _hr_slider_info = $MarginContainer/VBoxContainer/SliderHBox/SliderInfo/AlarmHrs

onready var _status_label = $MarginContainer/VBoxContainer/HBoxContainer/StatusLabel
onready var _progress_bar = $MarginContainer/VBoxContainer/HBoxContainer/ProgressBar
onready var TweenNode = $Tween

var curr_min:int = 0 # The current time
var curr_hr:int = 0
var slider_min:int = 0 # The value of the sliders
var slider_hr:int = 0
var alarm_min:int = 0 # Current time + slider value
var alarm_hr:int = 0


func _ready():
	# Reset anything that has a func to reset just to be sure
	reset_progress_bar()
	reset_slider_values()


# Called from parent and recieves new hour and minute. Then decides what to do with it based on status
func recieve_new_time(hour, minute):
#	print_debug("NEW TIME: %d:%02d" % [hour, minute])
	
	curr_hr = hour
	curr_min = minute
	
	match alarm_status:
		AlarmStatus.SET:
			if compare_time_to_alarm(hour, minute):
				set_alarm_status(AlarmStatus.ACTIVATED)
		AlarmStatus.PREP:
			prepare_alarm()


# Takes in an hour and minute value to compare to the set alarm time
# Returns TRUE if they match and false if they dont
func compare_time_to_alarm(hour, minute) -> bool:
	if hour == alarm_hr and minute == alarm_min:
		return true
	else:
		return false


# Takes in an AlarmStatus (int bc of Godot) and changes the alarm_status
func set_alarm_status(new_status: int):
#	var debug_status = alarm_status
	alarm_status = new_status
	
	# DEBUGGING
#	if debug_status != new_status: # Print the new status only if it's different
#		print("[SET, OFF, PREP, ACTIVATED] : " , new_status)
	
	reset_progress_bar() # Whenever the status changes clear the progress bar
	
	match alarm_status:
		AlarmStatus.ACTIVATED:
			sound_alarm()
			set_status_label("[Alarm Active]   %d:%02d" % [alarm_hr, alarm_min], Color.red)
		AlarmStatus.OFF:
			set_status_label("No Alarm Set", Color.white)
		AlarmStatus.PREP:
			set_status_label("[Alarm Idle]   %d:%02d" % [alarm_hr, alarm_min], Color.yellow)
		AlarmStatus.SET:
			start_alarm_tween()
			set_status_label("[Alarm Set]   %d:%02d" % [alarm_hr, alarm_min], Color.green)
		_:
			print_debug("error: illegal alarm_status")


# Add the current time to the slider values to create the alarm time and then set the status label
func prepare_alarm():
	alarm_hr = curr_hr + slider_hr
	alarm_min = curr_min + slider_min
	
	if alarm_min >= 60: # Keep minutes between 0 and 59
		alarm_min -= 60
		alarm_hr += 1
	
	if alarm_hr > 12: alarm_hr -= 12 # Keep hour between 1 and 12
	if alarm_hr == 0: alarm_hr = 12 # If the hour is adjusted to 0, that means it's 12
	
	if (slider_hr + slider_min) != 0: # If hr and min slider are at 0 do not set an alarm
		set_alarm_status(AlarmStatus.PREP)
	else:
		set_alarm_status(AlarmStatus.OFF)


# Calculate how long until the alarm goes off and sets the tween node accordingly
func start_alarm_tween():
	var alarm_len_s:int = (((slider_hr * 60) + slider_min) * 60) - OS.get_time().second # In seconds
	
	TweenNode.interpolate_property(_progress_bar, "value", 100, 0, alarm_len_s, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) # Tick down the progress bar as time passes
	TweenNode.start()


# Unless the alarm is activated stop all current tweens and refill the progress bar
func reset_progress_bar():
	if alarm_status != AlarmStatus.ACTIVATED: # If the alarm is active do NOT refill the progress bar
		TweenNode.stop_all() # End all current tweens
		TweenNode.interpolate_property(_progress_bar, "value", _progress_bar.value, 100, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) # Refill the bar
		TweenNode.start()


# Controls the repeating chime while the alarm is set to ACTIVATED
func sound_alarm():
	while alarm_status == AlarmStatus.ACTIVATED:
		Manager.play_chime(4)
		yield(get_tree().create_timer(1), "timeout")


# Updates the text and color of the alarm status label
func set_status_label(message: String, color: Color):
	_status_label.text = message
	_status_label.add_color_override("font_color", color)


# Returns the text set in the status label
func get_status_label() -> String:
	return _status_label.text


# Set the slider values to 0
func reset_slider_values():
	_hour_alarm_slider.value = 0
	_minute_alarm_slider.value = 0

# ---------------------------------------------------------------------- SIGNALS

func _on_MinAlarmSlider_value_changed(value):
	_min_slider_info.text = str(value) + " Mins"
	slider_min = value
	prepare_alarm()

func _on_HrAlarmSlider_value_changed(value):
	_hr_slider_info.text = str(value) + " Hrs"
	slider_hr = value
	prepare_alarm()


# Change the color of the progress bar based on the percentage of time passed
func _on_ProgressBar_value_changed(value):
	value /= 100 # Need value to be a float
	var hue:Color = Color.red.linear_interpolate(Color.green, value)
	
	_progress_bar.get_stylebox("fg").set("bg_color", hue)


# Set the alarm so long as both sliders aren't set to 0
func _on_AlarmStart_pressed():
	prepare_alarm() # Without this the sliders are NOT added to the current time. Prepare before setting
	if (slider_hr + slider_min) != 0:
		set_alarm_status(AlarmStatus.SET)

func _on_AlarmEnd_pressed():
	prepare_alarm()

func _on_AlarmReset_pressed():
	reset_slider_values()


func _on_BaseNode_new_time(hour, minute):
	recieve_new_time(hour, minute)
