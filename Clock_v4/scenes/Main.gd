extends PanelContainer

signal new_time(hour, minute) # Emitted when the minute changes

onready var alarm_module = $VBoxContainer/AlarmModule
onready var settings_module = $VBoxContainer/SettingsBase
onready var health_module = $VBoxContainer/HealthModule

onready var display_label:Label = find_node("TimeLabel")
onready var display_label_bg:Label = find_node("TimeLabelBackground")
onready var font_size_label:Label = find_node("FontSizeLabel")
onready var timer:Timer = $Timer

var second: int = 0
var pastMinute:int = -1 # Used to detect minute changes
var minute: int = 0 setget set_minute
var hour: int = 0 setget set_hour

var hourlyChime:bool = true
var halfHourlyChime:bool = true


func _ready():
	set_time()
	sync_with_system_time()
#	alarm_module.recieve_new_time(hour, minute) # Init the alarm with the current time
	sync_buttons_with_features()
	refresh_ui_size()
	Manager.probe()


# Rapidly checks the time to get exactly when the second switches over
# Then sets the time and makes sure the timer is started
func sync_with_system_time():
	var system_second = get_time().second
	while true:
		if system_second != get_time().second:
			timer.start()
			set_time()
			return


# Gets the system time from the OS
func get_time() -> Dictionary:
	return (OS.get_time())


# Sets the second, minute, hour variables from the system's time
# Sends time to alarm and checks if hour/half-hour chime should play
func set_time():
	var time: Dictionary = get_time()
	self.hour = time.hour # Have to set hour before minute based on alarm func calls
	self.minute = time.minute
	second = time.second
	
	if pastMinute != minute: # If the minute has changed
		emit_signal("new_time", hour, minute)
		if hourlyChime and minute == 0: # Hourly Chime
			alarm_module.play_chime(3)
		elif halfHourlyChime and minute == 30: # Half-Hourly Chime
			alarm_module.play_chime(2)
	
	update_display()


# Sets the hour and keeps it between 1 and 12
func set_hour(new_hour):
	hour = new_hour
	
	if hour > 12: hour -= 12 # Adjust from 24 hour time to 12 hour time
	if hour == 0: hour = 12 # If the hour is adjusted to 0, that means it's 12 


# Function that runs each time the minute changes
func set_minute(new_minute):
	pastMinute = minute
	minute = new_minute


# Sets the text in the main time display
func update_display():
	display_label.text = "%02d:%02d:%02d" % [hour, minute, second]


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
