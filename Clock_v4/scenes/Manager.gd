extends Node

onready var TweenNode:Tween = $Tween
onready var Chime:AudioStreamPlayer = $Chime


# Prints the status of the manager
func probe():
	print_debug("Manager is responding")


# ============================================================ GETTERS


# Returns a dict of all needed time values
func get_full_time() -> Dictionary:
	var time = OS.get_time()
	var output = {
		"h24":time.hour,
		"h12":time.hour,
		"min":time.minute,
		"sec":time.second,
		"raw":(time.hour * 60) + time.minute,
	}
	
	output.h12 %= 12
	if output.h12 < 1: output.h12 += 12
	
	return output


# Returns dict of 24-hour time hour, minute, second from the OS
func get_24HMS() -> Dictionary:
	return OS.get_time()


# Returns dict of 12-hour time hour, minute, second
func get_12HMS() -> Dictionary:
	var output = get_24HMS()
	
	output.hour %= 12
	if output.hour < 1: output.hour += 12
	
	return output


# Returns the time from the OS converted into minutes
# 0 == 1440 == midnight
func get_raw_mins() -> int:
	var temp = get_24HMS()
	return (temp.hour * 60) + temp.minutes


# Returns raw minutes from a given hour and minutes
func convert_to_raw_minutes(hour:int, mins:int) -> int:
	return ((hour * 60) + mins)


# Takes in raw_mins and converts it into human readable format HH:MMm
func convert_to_human_time(raw_mins:int, HR12:bool=true) -> String:
	# Clean raw minutes
	if raw_mins < 0:
		print_debug("ERROR: Invalid raw_mins")
		return("")
		
	raw_mins %= 1440
	
	# Set meridian
	var meridian:String = ""
	if HR12 == true:
		meridian = "a" if raw_mins < 720 else "p"
		
	# Set hour
	var hour:int = int(raw_mins / 60)
	if HR12 == true:
		hour %= 12
		if hour < 1: hour += 12
		
	var output:String = "%d:%02d%s" % [hour, (raw_mins % 60), meridian]
	return(output)


# ============================================================ FUNCS


# Takes in a label, 2 colors, and a time and interpolates the node's color between them
func tween_label_color_change(node:Label, color1:Color, color2:Color, time:int=1):
	TweenNode.interpolate_property(node, "custom_colors/font_color", color1, color2, time, Tween.TRANS_LINEAR)
	TweenNode.start()


# Takes in an int and plays the chime that many times
func play_chime(count:int):
	for i in count:
		Chime.play()
		yield(Chime, "finished")
