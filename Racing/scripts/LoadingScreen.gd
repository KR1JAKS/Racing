extends Control

@onready var progress_bar: ProgressBar = $ColorRect/VBoxContainer/MarginContainer/ProgressBar

var load_thread: Thread
var loading_scene: String
var progress: Array = []

func _ready():
	loading_scene = GameManager.target_scene
	progress_bar.value = 0
	start_async_load()

func start_async_load():
	load_thread = Thread.new()
	load_thread.start(_load_scene)

func _load_scene():
	ResourceLoader.load_threaded_request(loading_scene)

	while true:
		var status = ResourceLoader.load_threaded_get_status(loading_scene, progress)

		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				call_deferred("_update_progress", progress[0] * 90)
				await get_tree().process_frame

			ResourceLoader.THREAD_LOAD_LOADED:
				var scene = ResourceLoader.load_threaded_get(loading_scene)
				call_deferred("_finalize_loading", scene)
				break

			ResourceLoader.THREAD_LOAD_FAILED:
				print("Ошибка загрузки сцены")
				break
	call_deferred("_thread_finished")

func _update_progress(value: float):
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", value, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func _finalize_loading(scene: PackedScene):
	var instance = scene.instantiate()
	instance.hide()
	get_tree().root.add_child(instance)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	instance.show()
	queue_free()

func _thread_finished():
	load_thread.wait_to_finish()
