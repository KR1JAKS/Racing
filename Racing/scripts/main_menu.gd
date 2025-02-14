extends Control

var label_original_position: Vector2
@onready var music_player = $MusicPlayer
@onready var sound_player = $SoundPlayer

func _ready():
	label_original_position = $ColorRect/LabelName.position

	var center_container = $ColorRect/CenterContainer
	var label = $ColorRect/LabelName

	center_container.scale = Vector2(0.5, 0.5)
	center_container.modulate.a = 0

	label.position.x = get_viewport_rect().size.x + 100
	label.modulate.a = 0

	music_player.play()

	var tween = create_tween().set_parallel(false)

	tween.tween_property(center_container, "scale", Vector2(1, 1), 0.8)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(center_container, "modulate:a", 1.0, 0.4)

	tween.tween_callback(func(): 
		var label_tween = create_tween().set_parallel()
		label_tween.tween_property(label, "position", label_original_position, 0.8)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(label, "modulate:a", 1.0, 0.5)
	)

	for button in get_tree().get_nodes_in_group("menu_buttons"):
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	pass

func _on_button_hover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button, "self_modulate", Color(0.8, 0.8, 0.8), 0.15)

func _on_button_unhover(button: Button):
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(button, "self_modulate", Color.WHITE, 0.15)

func _on_start_button_pressed() -> void:
	sound_player.play()
	await get_tree().create_timer(1).timeout
	music_player.stop()
	GameManager.target_scene = "res://Scenes/world.tscn"
	get_tree().change_scene_to_file("res://Scenes/LoadingScreen.tscn")

func _on_exit_button_pressed() -> void:
	sound_player.play()
	await get_tree().create_timer(1).timeout
	music_player.stop()
	get_tree().quit()

func _on_settings_button_pressed() -> void:
	sound_player.play()
	var settings_menu = preload("res://Scenes/settings_menu.tscn").instantiate()
	add_child(settings_menu)
