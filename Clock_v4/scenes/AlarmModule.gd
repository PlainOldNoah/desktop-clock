extends PanelContainer

enum AlarmStatus {SET, OFF, PREP, ACTIVATED}
export(AlarmStatus) var alarm_status = AlarmStatus.OFF setget set_alarm_status

onready var minute_alarm_slider = find_node("MinAlarmSlider")
onready var hour_alarm_slider = find_node("HrAlarmSlider")
onready var min_slider_info = find_node("AlarmMins")
onready var hr_slider_info = find_node("AlarmHrs") 
onready var status_label = find_node("StatusLabel")
onready var progress_bar = find_node("ProgressBar")
onready var TweenNode = $Tween

var current_time:int = 0
var slider_min:int = 0
var slider_hr:int = 0
var alarm_time:int = 0


func _ready():
	# Reset anything that has a func to reset just to be sure
	reset_progress_bar()
	reset_slider_values()


# Called from parent and recieves new hour and minute. Then decides what to do with it based on status
func recieve_new_time(raw_minute):
	
	current_time = raw_minute
	
	match alarm_status:
		AlarmStatus.SET:
			if current_time == alarm_time:
				set_alarm_status(AlarmStatus.ACTIVATED)
		AlarmStatus.PREP:
			prepare_alarm()


# Add the current time to the slider values to create the alarm time
func prepare_alarm():
	alarm_time = current_time + slider_hr + slider_min
	
	if (slider_hr + slider_min) != 0: # If hr and min slider are at 0 do not set an alarm
		set_alarm_status(AlarmStatus.PREP)
	else:
		set_alarm_status(AlarmStatus.OFF)


# Takes in an AlarmStatus (int bc of Godot) and changes the alarm_status
func set_alarm_status(new_status: int):
	alarm_status = new_status
	
	reset_progress_bar() # Whenever the status changes clear the progress bar
	
	var text:String = Manager.convert_to_human_time(alarm_time)
	
	match alarm_status:
		AlarmStatus.ACTIVATED:
			sound_alarm()
			set_status_label("[Alarm Active]  " + text, Color.red)
		AlarmStatus.OFF:
			set_status_label("[No Alarm Set]", Color.white)
		AlarmStatus.PREP:
			set_status_label("[Alarm Idle]  " + text, Color.yellow)
		AlarmStatus.SET:
			start_alarm_tween()
			set_status_label("[Alarm Set]  " + text, Color.green)
		_:
			print_debug("ERROR: illegal alarm_status")


# Calculate how long until the alarm goes off and sets the tween node accordingly
func start_alarm_tween():
	var alarm_len_s:int = ((slider_hr + slider_min) * 60) - OS.get_time().second # In seconds
	
	TweenNode.interpolate_property(progress_bar, "value", 100, 0, alarm_len_s, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) # Tick down the progress bar as time passes
	TweenNode.start()


# Unless the alarm is activated stop all current tweens and refill the progress bar
func reset_progress_bar():
	if alarm_status != AlarmStatus.ACTIVATED: # If the alarm is active do NOT refill the progress bar
		TweenNode.stop_all()
		TweenNode.interpolate_property(progress_bar, "value", progress_bar.value, 100, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT) # Refill the bar
		TweenNode.start()

# Controls the repeating chime while the alarm is set to ACTIVATED
func sound_alarm():
	while alarm_status == AlarmStatus.ACTIVATED:
		Manager.play_chime(4)
		yield(get_tree().create_timer(1), "timeout")


# Updates the text and color of the alarm status label
func set_status_label(message: String, color: Color):
	status_label.text = message
	status_label.add_color_override("font_color", color)


# Set the slider values to 0
func reset_slider_values():
	hour_alarm_slider.value = 0
	minute_alarm_slider.value = 0

# ---------------------------------------------------------------------- SIGNALS

func _on_MinAlarmSlider_value_changed(value):
	min_slider_info.text = str(value) + (" Mins" if value != 1 else " Min")
	slider_min = value
	prepare_alarm()


func _on_HrAlarmSlider_value_changed(value):
	hr_slider_info.text = str(value / 60) + (" Hrs" if value != 60 else " Hr")
	slider_hr = value
	prepare_alarm()


# Change the color of the progress bar based on the percentage of time passed
func _on_ProgressBar_value_changed(value):
	value /= 100 # Need value to be a float
	var hue:Color = Color.red.linear_interpolate(Color.green, value)
	
	progress_bar.get("custom_styles/fg").set("bg_color", hue)


# Set the alarm so long as both sliders aren't set to 0
func _on_AlarmStart_pressed():
	prepare_alarm() # Without this the sliders are NOT added to the current time. Prepare before setting
	if (slider_hr + slider_min) != 0:
		set_alarm_status(AlarmStatus.SET)


func _on_AlarmEnd_pressed():
	prepare_alarm()


func _on_AlarmReset_pressed():
	reset_slider_values()
	prepare_alarm()


func _on_BaseNode_new_minute(raw_minute):
	recieve_new_time(raw_minute)
