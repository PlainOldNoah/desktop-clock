extends PanelContainer

signal night_mode_active(status)

onready var night_start_slider:HSlider = find_node("NightStartSlider")
onready var night_end_slider:HSlider = find_node("NightEndSlider")
onready var night_mode_label:Label = find_node("NightModeLabel")
onready var recess_label:Label = find_node("RecessLabel")

var nightMode:bool = true
var recessMode:bool = true

var current_time:int = 0
var nightStart:int = 1410 # 11:30p
var nightEnd:int = 360 # 6:00p
var recessInterval:int = 0 # Value of slider
var recessNextAlarm:int = 0


func _ready():
	yield(get_tree().get_root(), "ready")
	set_night_mode_text()
	night_start_slider.value = nightStart
	night_end_slider.value = nightEnd


# Takes in an hour and minute and converts it to raw minutes then compares it to the night mode sliders
func recieve_new_time(raw_minute):
	check_if_night_mode(raw_minute)
	check_if_recess_time(raw_minute)


# Compare raw minutes to night mode's nightStart and nightEnd, then change color of display
func check_if_night_mode(newTime:int):
	if (nightStart >= nightEnd) and not ((newTime < nightStart) and (newTime >= nightEnd)): # When time is between nightStart and nightEnd (or equal) with wraparound
		emit_signal("night_mode_active", true)
	elif (nightStart < nightEnd) and (newTime >= nightStart and newTime < nightEnd): # When time is between nightStart and nightEnd without wraparound
		emit_signal("night_mode_active", true)
	else:
		emit_signal("night_mode_active", false)


# Sets the text of the label based on the slider times and toggle button state
func set_night_mode_text():
	var output:String = "Active: " if nightMode else "Disabled: "
	
	output += Manager.convert_to_human_time(nightStart) + " - "
	output += Manager.convert_to_human_time(nightEnd)
	
	night_mode_label.set_text(output)


# Compares an input time to the set recess time
func check_if_recess_time(newTime:int):
	if (recessMode) and (newTime == recessNextAlarm):
		Manager.play_chime(1)


# Sets the recess time and the associated label
func prep_recess():
	var output:String = ""
	if recessMode == false or recessInterval == 0:
		output = "Off"
		recessNextAlarm = -1
	else:
		recessNextAlarm = (current_time + recessInterval) % 1440
		output = str(recessInterval) + (" Mins" if recessInterval > 1 else " Min")
	
	recess_label.set_text(output)


# ====================================================================== SIGNALS


func _on_BaseNode_new_minute(raw_minute):
	current_time = raw_minute
	recieve_new_time(raw_minute)


func _on_NightStartSlider_value_changed(value):
	nightStart = value
	set_night_mode_text()
	check_if_night_mode(current_time)


func _on_NightEndSlider_value_changed(value):
	nightEnd = value
	set_night_mode_text()
	check_if_night_mode(current_time)


func _on_RecessMinSlide_value_changed(value):
	recessInterval = value
	prep_recess()


# ---------------------------------------------------------------------- TOGGLE BUTTONS


func _on_NightModeBtn_toggled(button_pressed):
	nightMode = button_pressed
	set_night_mode_text()


func _on_ToggleRecessButton_toggled(button_pressed):
	recessMode = button_pressed
	prep_recess()
