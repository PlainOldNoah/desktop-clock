extends Node

onready var TweenNode = $Tween


# Prints the status of the manager
func probe():
	print_debug("Manager is responding")


# ============================================================ GETTERS


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
	return ((temp.hour * 60) + temp.minute)


# Returns raw minutes from a given hour and minutes
func convert_to_raw_minutes(hour:int, mins:int) -> int:
	return ((hour * 60) + mins)


# ============================================================ FUNCS


# Takes in a label, 2 colors, and a time and interpolates the node's color between them
func tween_label_color_change(node:Label, color1:Color, color2:Color, time:int=1):
	TweenNode.interpolate_property(node, "custom_colors/font_color", color1, color2, time, Tween.TRANS_LINEAR)
	TweenNode.start()
