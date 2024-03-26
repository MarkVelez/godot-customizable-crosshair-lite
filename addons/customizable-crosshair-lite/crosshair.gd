# Uncomment if you want to see the cursor in the editor
#@tool
extends Control

@export_category("Crosshair settings")
@export var crosshairThickness: float ## The thickness of the lines.
@export var crosshairSize: float ## The length of the lines.
@export var crosshairGap: float ## The distance between the middle of the screen and the starts of the lines.
@export var crosshairColor: Color ## The color of the crosshair.

@export_group("Style settings")
@export var crosshairDot: bool ## Toggle for the middle dot

@export_subgroup("Outline settings")
@export var crosshairOutline: bool ## Toggle for an outline for the lines
@export var crosshairOutlineThickness: float ## The thickness of the outline

# A dictionary that holds all the config values for the crosshair
# I recommend not directly changing the values as it could cause possible issues like type mismatch
# Use the getCrosshairSettings function instead
var crosshairConfig: Dictionary


func _ready() -> void:
	# Runs only if @tool is uncommented
	if Engine.is_editor_hint():
		# Centers the crosshair
		set_anchors_preset(Control.PRESET_CENTER, true)
		# Makes it so the crosshair is ignored by mouse clicks
		mouse_filter = Control.MOUSE_FILTER_PASS
	
	updateCrosshairConfig()


# Checks if the received dictionary matches the crosshairConfig dictionary before overwriting it
func validConfig(config: Dictionary) -> bool:
	# Check if there is a size mismatch
	if config.size() != crosshairConfig.size():
		print("Config validation failed due to size mismatch!")
		return false
	
	# Check if there are any missing entries
	if not config.has_all(crosshairConfig.keys()):
		print("Config validation failed due to key mismatch!")
		return false
	
	# Check if there is a value type mismatch
	for value in config:
		if typeof(config[value]) != typeof(crosshairConfig[value]):
			print("Config validation failed due to incorrect type for ", value, "!")
			print("Expected ", type_string(typeof(crosshairConfig[value])), " but got ", type_string(typeof(value)))
			return false
	
	return true


# Converts the config dictionary to a JSON string
func getConfigString() -> String:
	var dict: Dictionary = crosshairConfig.duplicate()
	
	# JSON does not like Godot color values so it is converted to an array here
	dict["color"] = [
		dict["color"].r,
		dict["color"].g,
		dict["color"].b,
		dict["color"].a
	]
	
	var string = JSON.stringify(dict, "", false)
	return string


# Convert the JSON string form of the config to a dictionary
func parseConfigString(configString: String) -> void:
	var config = JSON.parse_string(configString)
	
	# Check if the parse failed
	if config == null:
		print("Incorrect config string!")
		return
	
	# Convert the color value back to a proper color value
	config["color"] = Color(
		config["color"][0],
		config["color"][1],
		config["color"][2],
		config["color"][3]
	)
	
	# For some reason lineStyle has the incorrect type so there is a conversion done here to int
	config["lineStyle"] = type_convert(config["lineStyle"], 2)
	
	getCrosshairSettings(config)


# Get the crosshair config values from the config dictionary
func getCrosshairSettings(config: Dictionary) -> void:
	# Check if the received dictionary is correct
	if validConfig(config):
		crosshairThickness = config["thickness"]
		crosshairSize = config["size"]
		crosshairGap = config["gap"]
		crosshairColor = config["color"]
		crosshairDot = config["dot"]
		crosshairOutline = config["outline"]
		crosshairOutlineThickness = config["outlineThickness"]
		queue_redraw()
	else:
		print("Invalid config!")


# Updates the values of the config dictionary as well as the crosshair
func updateCrosshairConfig() -> void:
	crosshairConfig = {
		"thickness": crosshairThickness,
		"size": crosshairSize,
		"gap": crosshairGap,
		"color": crosshairColor,
		"dot": crosshairDot,
		"outline": crosshairOutline,
		"outlineThickness": crosshairOutlineThickness
	}
	queue_redraw()


func _draw() -> void:
	# Formular for the start point of the crosshair lines
	var lineStartPoint: float = (crosshairGap + (crosshairThickness / 2))
	# Formular for the end point of the crosshair lines
	var lineEndPoint: float = (crosshairSize + crosshairGap + (crosshairThickness / 2))
	
	# Array of the start point and end point vectors of each crosshair line
	var linePoints: PackedVector2Array = [
		Vector2(0.0, -lineStartPoint), # Top start
		Vector2(0.0, -lineEndPoint), # Top end
		Vector2(0.0, lineStartPoint), # Bottom start
		Vector2(0.0, lineEndPoint), # Bottom end
		Vector2(-lineStartPoint, 0.0), # Left start
		Vector2(-lineEndPoint, 0.0), # Left end
		Vector2(lineStartPoint, 0.0), # Right start
		Vector2(lineEndPoint, 0.0) # Right end
	]
	
	# Formular for the start point of the crosshair outline lines
	var outlineStartPoint: float = (crosshairGap + (crosshairThickness / 2) - (crosshairOutlineThickness))
	# Formular for the end point of the crosshair outline lines
	var outlineEndPoint: float = (crosshairSize + crosshairGap + (crosshairThickness / 2) + (crosshairOutlineThickness))
	
	# Array of the start point and end point vectors of each crosshair outline line
	var outlinePoints: PackedVector2Array = [
		Vector2(0.0, -outlineStartPoint), # Top start
		Vector2(0.0, -outlineEndPoint), # Top end
		Vector2(0.0, outlineStartPoint), # Bottom start
		Vector2(0.0, outlineEndPoint), # Bottom end
		Vector2(-outlineStartPoint, 0.0), # Left start
		Vector2(-outlineEndPoint, 0.0), # Left end
		Vector2(outlineStartPoint, 0.0), # Right start
		Vector2(outlineEndPoint, 0.0) # Right end
	]
	
	# Draw the outline lines under the crosshair lines if crosshair outline is enabled
	if crosshairOutline:
		draw_multiline(outlinePoints, Color(Color.BLACK, crosshairColor.a), crosshairThickness + (crosshairOutlineThickness * 2))
	
	# Draw the crosshair lines
	draw_multiline(linePoints, crosshairColor, crosshairThickness)
	
	# Draw a square behind the crosshair dot to be used as an outline if crosshair outline is enabled
	if crosshairOutline && crosshairDot:
		draw_rect(Rect2(-((crosshairThickness / 2) + crosshairOutlineThickness), -((crosshairThickness / 2) + crosshairOutlineThickness), crosshairThickness + (crosshairOutlineThickness * 2), crosshairThickness + (crosshairOutlineThickness * 2)), Color(Color.BLACK, crosshairColor.a))
	
	# Draw a square in the middle of the screen if crosshair dot is enabled
	if crosshairDot:
		draw_rect(Rect2(-crosshairThickness / 2, -crosshairThickness / 2, crosshairThickness, crosshairThickness), crosshairColor)
	
	# Runs only if @tool is uncommented
	if Engine.is_editor_hint():
		# Used to update the crosshair when the visibility is toggled
		if visibility_changed:
			queue_redraw()
