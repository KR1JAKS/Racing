extends Control

@onready var resolution_option: OptionButton = $ColorRect/VBoxContainer/MarginContainer/HBoxContainer/ResolutionOption
@onready var fullscreen_check: CheckBox = $ColorRect/VBoxContainer/MarginContainer2/HBoxContainer2/FullscreenCheck
@onready var sound_player: AudioStreamPlayer = $SoundPlayer

var resolutions: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1280, 720),
	Vector2i(640, 480)
]

func _ready() -> void:
	resolution_option.add_item("1920x1080")
	resolution_option.add_item("1600x900")
	resolution_option.add_item("1280x720")
	resolution_option.add_item("640x480")

	for i in range(resolution_option.item_count):
		if resolutions[i] == Settings.resolution:
			resolution_option.selected = i
			break
	fullscreen_check.button_pressed = Settings.fullscreen

func _on_resolution_option_item_selected(index: int) -> void:
	Settings.resolution = resolutions[index]
	Settings.apply_settings()
	Settings.save_settings()

func _on_fullscreen_check_toggled(button_pressed: bool) -> void:
	Settings.fullscreen = button_pressed
	Settings.apply_settings()
	Settings.save_settings()

func _on_back_button_pressed() -> void:
	sound_player.play()
	await get_tree().create_timer(1.5).timeout
	queue_free()
	get_parent().show()
