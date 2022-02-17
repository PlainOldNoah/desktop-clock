extends PanelContainer

signal new_minute(raw_minute) # Emitted when the minute changes

onready var alarm_module = $VBoxContainer/AlarmModule
onready var settings_module = $VBoxContainer/SettingsBase
onready var health_module = $VBoxContainer/HealthModule

onready var display_label:Label = find_node("TimeLabel")
onready var display_label_bg:Label = find_node("TimeLabelBackground")
onready var font_size_label:Label = find_node("FontSizeLabel")
onready var timer:Timer = $Timer

var pastMinute:int = -1 # Used to detect minute changes

var hourlyChime:bool = true
var halfHourlyChime:bool = true


func _ready():
	Manager.probe()
	set_time()
	sync_with_system_time()
	sync_buttons_with_features()
	refresh_ui_size()


# Rapidly checks the time to get exactly when the second switches over
# Then sets the time and makes sure the timer is started
func sync_with_system_time():
	var system_second = Manager.get_24HMS().second
	while true:
		if system_second != Manager.get_24HMS().second:
			timer.start()
			set_time()
			return


# Sets the second, minute, hour variables from the system's time
# Sends time to alarm and checks if hour/half-hour chime should play
func set_time():
	var time: Dictionary = Manager.get_full_time()
	
	if pastMinute != time.raw:
		print("NEW_MIN", pastMinute, ", ", time.raw)
		periodic_chimes(time.raw)
		emit_signal("new_minute", time.raw)
	pastMinute = time.raw
	
	update_display(time.h12, time.min, time.sec)


# Plays chimes on the hour and half hour if toggled
func periodic_chimes(check_min:int):
	if hourlyChime and check_min % 11 == 0: # Hourly Chime
		Manager.play_chime(3)
	elif halfHourlyChime and check_min % 30 == 0: # Half-Hourly Chime
		Manager.play_chime(2)


# Sets the text in the main time display
func update_display(hr:int=0, mn:int=0, sd:int=0):
	display_label.text = "%02d:%02d:%02d" % [hr, mn, sd]


# Takes in a color and changes the display's font color
func change_display_color(color:Color):
	display_label.add_color_override("font_color", color)


# Adjusts features based on button state
func sync_buttons_with_features():
	alarm_module.visible = false
	settings_module.visible = false
	health_module.visible = false
	_on_FontSizeSlider_value_changed(48) # Set to default font size
	_on_ToggleTopWindow_toggled(true)


# Resizes the UI to fit all the correct modules
# I don't fully know how this works but the order of commands does matter
func refresh_ui_size():
	self.visible = false
	self.visible = true
	self.rect_size = Vector2.ZERO # Make the program as small as possible
	OS.window_size = Vector2(self.rect_size.x, self.rect_size.y) # Set the window to program size

# ====================================================================== SIGNALS


# Emitted when the second timer timeouts each second
func _on_Timer_timeout():
	set_time()


# When the font slider changes, change the font size
func _on_FontSizeSlider_value_changed(value):
	display_label.get_font("font").size = value
	display_label_bg.get_font("font").size = value
	font_size_label.text = ("Display Size (%d)" % [value])


# Refresh the UI size if the user clicks or scrolls over the font size slider
func _on_FontSizeSlider_gui_input(event):
	if event.is_action_released("click") or event.is_action_released("scroll"):
		refresh_ui_size()


# ---------------------------------------------------------------------- TOGGLE BUTTONS


# Toggles the visibility of the alarm module
func _on_ToggleAlarmButton_toggled(button_pressed):
	alarm_module.visible = button_pressed
	refresh_ui_size()

# Toggles the visibility of the settings module
func _on_ToggleSettingsButton_toggled(button_pressed):
	settings_module.visible = button_pressed
	refresh_ui_size()


func _on_ToggleHealthButton_toggled(button_pressed):
	health_module.visible = button_pressed
	refresh_ui_size()


# Toggle if the window should stay on top of everything else. On by default
func _on_ToggleTopWindow_toggled(button_pressed):
	OS.set_window_always_on_top(button_pressed)


func _on_ToggleHourChime_toggled(button_pressed):
	hourlyChime = button_pressed


func _on_ToggleHalfHourChime_toggled(button_pressed):
	halfHourlyChime = button_pressed


func _on_TEST_pressed():
	
#	Manager.tween_label_color_change(display_label, Color.red, Color.yellow, 2) # Option 1

#	Manager.TweenNode.interpolate_property(display_label, "custom_colors/font_color", Color.aliceblue, Color.yellow, 2, Tween.TRANS_LINEAR) # Tick down the progress bar as time passes OPTION 2
#	Manager.TweenNode.start()
	pass
