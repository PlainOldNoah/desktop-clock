extends PanelContainer

enum State {DISABLED, IDLE, ACTIVE}
export(State) var nightModeState = State.DISABLED

onready var night_start_slider:HSlider = find_node("NightStartSlider")
onready var night_end_slider:HSlider = find_node("NightEndSlider")
onready var night_mode_label:Label = find_node("NightModeLabel")

var nightMode:bool = true
var movementBreak:bool = true

var nightModeStart:Dictionary = time_calc(1410) # 11:30p
var nightModeEnd:Dictionary = time_calc(360)    # 6:00p


func _ready():
	set_night_mode_text()
	night_start_slider.value = 1410
	night_end_slider.value = 360


# Takes in an hour and minute and converts it to raw minutes then compares it to the night mode sliders
func recieved_new_time(hour, minute):
	var newTime = ((hour * 60) + minute) % 1440
	
	check_if_night_mode(newTime)


# Compare raw minutes to night mode's start and end, then change color of display
func check_if_night_mode(newTime:int):
	var start = nightModeStart["rawMinutes"] % 1440
	var end = nightModeEnd["rawMinutes"] % 1440
	
#	if (start >= end) and ((newTime >= start and newTime <= 1440) or (newTime >= 0 and newTime < end)): # When time is between start and end (or equal) with wraparound
	if (start >= end) and not ((end < newTime) and (newTime <= start)): # When time is between start and end (or equal) with wraparound
#		print("TRUE", ", ", start, ", ", newTime, ", ", end)
		self.get_parent().get_parent().change_display_color(Color.yellow)
	elif (start < end) and (newTime >= start and newTime < end): # When time is between start and end without wraparound
#		print("TRUE2", ", ", start, ", ", newTime, ", ", end)
		self.get_parent().get_parent().change_display_color(Color.yellow)
	else:
#		print("FALSE", ", ", start, ", ", newTime, ", ", end)
		self.get_parent().get_parent().change_display_color(Color.white)


# Sets the text of the label based on the slider times and toggle button state
func set_night_mode_text():
	var output:String = ""
	if nightMode:
		output += "Active: "
	else:
		output += "Disabled: "
	
	if nightModeStart["24Hour"] == 0 and nightModeStart["minutes"] == 0:
		output += "Midnight"
	elif nightModeStart["24Hour"] == 12 and nightModeStart["minutes"] == 0:
		output += "Noon"
	else:
		output += str(nightModeStart["12Hour"]) + ":" + str(nightModeStart["minutes"]).pad_zeros(2)
	
	output += " - "
	
	if nightModeEnd["24Hour"] == 0 and nightModeEnd["minutes"] == 0:
		output += "Midnight"
	elif nightModeEnd["24Hour"] == 12 and nightModeEnd["minutes"] == 0:
		output += "Noon"
	else:
		output += str(nightModeEnd["12Hour"]) + ":" + str(nightModeEnd["minutes"]).pad_zeros(2)
	
	night_mode_label.set_text(output)


# Takes in a int (raw minutes) that represents the num of mins from midnight
# Returns a dictionary of 12 Hour and 24 Hour time as well as remainder minutes and raw minutes
func time_calc(minutes:int) -> Dictionary:
	var output:Dictionary = {
		"rawMinutes": minutes % 1441, # 1440 is max mins and included so use 1440 + 1
		"minutes": minutes % 60,
		"24Hour": (minutes / 60) % 24,
		"12Hour": 0.0,
	}
	
	var temp = output["24Hour"] % 12
	if temp < 1:
		temp += 12
	output["12Hour"] = temp
	
	return output


# USED FOR TESTING FEATURES
func RUN_TEST(): 
	# TESTING FOR CHECKING IF A TIME IS WITHIN THE NIGHT MODE SLIDERS
#	var debug_start = nightModeStart["rawMinutes"] - 5
#	if debug_start < 0: debug_start += 1440
#	print("\n")
#	for i in 10:
#		recieved_new_time(0, debug_start + i)
#	print("\n")
#	debug_start = nightModeEnd["rawMinutes"] - 5
#	if debug_start < 0: debug_start += 1440
#	for i in 10:
#		recieved_new_time(0, debug_start + i)
	
	# 6 = 360, 930 = 570
	for i in 10:
		check_if_night_mode(1285 + i)


# ====================================================================== SIGNALS


func _on_BaseNode_new_time(hour, minute):
	recieved_new_time(hour, minute)


func _on_MovementMinSlide_value_changed(value):
	pass # Replace with function body.


func _on_NightStartSlider_value_changed(value):
	nightModeStart = time_calc(value)
	set_night_mode_text()


func _on_NightEndSlider_value_changed(value):
	nightModeEnd = time_calc(value)
	set_night_mode_text()


# ---------------------------------------------------------------------- TOGGLE BUTTONS


func _on_NightModeBtn_toggled(button_pressed):
	nightMode = button_pressed
	set_night_mode_text()


func _on_MovementBtn_toggled(button_pressed):
	RUN_TEST()
