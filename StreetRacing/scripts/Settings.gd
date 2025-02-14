extends Node

var config := ConfigFile.new()
var resolution: Vector2i = Vector2i(640, 480)
var fullscreen: bool = false

func _ready() -> void:
	load_settings()

func load_settings() -> void:
	var err = config.load("user://settings.cfg")
	if err == OK:
		resolution = config.get_value("display", "resolution", Vector2i(640, 480))
		fullscreen = config.get_value("display", "fullscreen", false)
	apply_settings()

func save_settings() -> void:
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "fullscreen", fullscreen)
	config.save("user://settings.cfg")

func apply_settings() -> void:
	if fullscreen:
		get_window().mode = Window.MODE_FULLSCREEN
	else:
		get_window().mode = Window.MODE_WINDOWED
		get_window().size = resolution

		var screen_size = DisplayServer.screen_get_size()
		var window_size = get_window().size

		var window_position = (screen_size - window_size) / 2

		get_window().position = window_position
