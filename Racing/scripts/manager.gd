extends Node

var game_paused: bool = false

@onready var pause_menu = $"../CanvasLayer/PauseMenu"

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		game_paused = !game_paused
		
	if game_paused == true:
		get_tree().paused = true
		pause_menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		get_tree().paused = false
		pause_menu.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_resume_pressed() -> void:
	game_paused = !game_paused


func _on_quit_pressed() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false
	pause_menu.queue_free()
	var player = get_node("../player")
	var map = get_node("../Map")
	var minimap = get_node("../CanvasLayer2")
	minimap.queue_free()
	map.queue_free()
	player.queue_free()
	queue_free()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
