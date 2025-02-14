extends VehicleBody3D

@onready var drift_sound: AudioStreamPlayer = $DriftSound
@onready var driving_sound: AudioStreamPlayer = $DrivingSound
@onready var idle_sound: AudioStreamPlayer = $IdleSound
@onready var nos_sound: AudioStreamPlayer = $NOSSound
var was_boosting: bool = false

var engine_on: bool = false
@onready var engine_status_ui: CanvasLayer = $EngineStatusUI
@onready var engine_status_label: Label = $EngineStatusUI/Label
@onready var engine_start_sound: AudioStreamPlayer = $EngineStartSound

var headlights_on: bool = false
@onready var front_left_light: SpotLight3D = $body/FrontLeftLight
@onready var front_right_light: SpotLight3D = $body/FrontRightLight
@onready var rear_left_light: OmniLight3D = $body/RearLeftLight
@onready var rear_right_light: OmniLight3D = $body/RearRightLight

const DEFAULT_COLOR = Color("#cfffff")
const YELLOW_COLOR = Color.YELLOW
const RED_COLOR = Color("#8b0000")
const GRAY_COLOR = Color("#7c7c7c")

@onready var body_mesh: MeshInstance3D = $body
var surface2_material: StandardMaterial3D
var surface3_material: StandardMaterial3D
var surface4_material: StandardMaterial3D

const MAX_STEER = 0.8
const ENGINE_POWER = 400
const DRIFT_STRENGTH = 5000
const DRIFT_DECELERATION = 20000
const DRIFT_MIN_SPEED = 0.01

const CAMERA_LERP_SPEED = 20.0
const CAMERA_TRANSFORM_LERP_SPEED = 5.0

const MUSIC_PATH = "res://sounds/"
const MAX_ROLL_ANGLE = 60
const TIMER_UI_DELAY = 5.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_3d: Camera3D = $CameraPivot/Camera3D
@onready var reverse_camera: Camera3D = $CameraPivot/ReverseCamera
@onready var left_camera: Camera3D = $LeftCamera
@onready var right_camera: Camera3D = $RightCamera
@onready var radio: AudioStreamPlayer3D = $Radio
@onready var radio_ui: CanvasLayer = $RadioUI
@onready var track_name_label: Label = $RadioUI/TrackNameLabel
@onready var timer_ui: CanvasLayer = $TimerUI
@onready var timer_label: Label = $TimerUI/TimerLabel
@onready var stamina_bar: ProgressBar = $StaminaUI/ProgressBar
@onready var blur_effect: ColorRect = $BlurEffect
@onready var flip_timer: Timer = $TimerUI/Timer
@onready var ui_delay_timer: Timer = Timer.new()

@onready var speedometer_ui: CanvasLayer = $SpeedometerUI
@onready var speed_label: RichTextLabel = $SpeedometerUI/SpeedLabel

@onready var x1_camera: Camera3D = $X1
@onready var x2_camera: Camera3D = $X2
@onready var x3_camera: Camera3D = $X3

var cameras: Array[Camera3D]
var current_camera_index: int = 0
var camera_timer: Timer
var camera_cycle_active: bool = false

var stamina_timer: Timer
var max_stamina: float = 100.0
var current_stamina: float = max_stamina
var stamina_depletion_rate: float = 40.0
var stamina_regen_rate: float = 25.0
var is_boosting: bool = false
var is_recharging: bool = false

var is_flipped: bool = false
var look_at: Vector3

var music_files: Array[String] = []
var current_track_index: int = 0
var track_display_time = 2.0
var track_display_timer: float = 0.0

var is_drifting = false
var drift_direction = 0

var displayed_speed: float = 0.0

@export var respawn_point: Vector3

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	look_at = global_position

	load_music_files()
	radio.finished.connect(play_next_track)

	stamina_bar.max_value = max_stamina
	blur_effect.visible = false

	timer_ui.visible = false
	flip_timer.wait_time = 10.0
	flip_timer.one_shot = true
	flip_timer.timeout.connect(_flip_car)

	ui_delay_timer.wait_time = TIMER_UI_DELAY
	ui_delay_timer.one_shot = true
	ui_delay_timer.timeout.connect(_show_timer_ui)
	add_child(ui_delay_timer)

	stamina_timer = Timer.new()
	add_child(stamina_timer)
	stamina_timer.wait_time = 2.0
	stamina_timer.one_shot = true
	stamina_timer.timeout.connect(_on_stamina_timer_timeout)

	cameras = [x1_camera, x2_camera, x3_camera]

	camera_timer = Timer.new()
	add_child(camera_timer)
	camera_timer.wait_time = 3.0
	camera_timer.timeout.connect(_switch_to_next_camera)
	camera_timer.one_shot = false

	_activate_camera(camera_3d)

	speed_label.text = "[color=#ffffff]0 км ч[/color]"
	speed_label.bbcode_enabled = true

	front_left_light.visible = false
	front_right_light.visible = false
	rear_left_light.visible = false
	rear_right_light.visible = false

	surface2_material = body_mesh.get_active_material(2).duplicate()
	surface3_material = body_mesh.get_active_material(3).duplicate()
	surface4_material = body_mesh.get_active_material(4).duplicate()
	body_mesh.set_surface_override_material(2, surface2_material)
	body_mesh.set_surface_override_material(3, surface3_material)
	body_mesh.set_surface_override_material(4, surface4_material)
	
	engine_status_ui.visible = false
	var engine_sound = load("res://SoundsEffectsCar/engine_start.mp3")
	engine_start_sound.stream = engine_sound if engine_sound else null

	drift_sound.stream = load("res://SoundsEffectsCar/drift.mp3")
	driving_sound.stream = load("res://SoundsEffectsCar/driving.mp3")
	idle_sound.stream = load("res://SoundsEffectsCar/idle.mp3")
	nos_sound.stream = load("res://SoundsEffectsCar/NOS.mp3")

	drift_sound.stream.loop = true
	driving_sound.stream.loop = true
	idle_sound.stream.loop = true
	nos_sound.stream.loop = false

	if respawn_point == Vector3.ZERO:
		respawn_point = global_transform.origin

func _physics_process(delta):
	var move_input = Input.get_axis("ui_down", "ui_up")
	var steer_input = Input.get_axis("ui_right", "ui_left")

	if not engine_on:
		move_input = 0.0
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down"):
			if not engine_status_ui.visible:
				engine_status_label.text = "Для движения заведите двигатель F"
				engine_status_label.modulate = Color.WHITE
				engine_status_ui.visible = true
				get_tree().create_timer(2.0).connect("timeout", Callable(engine_status_ui, "set_visible").bind(false))

	var local_velocity = linear_velocity.dot(transform.basis.z)
	var is_reversing = move_input < 0 or local_velocity < -1.0

	is_drifting = Input.is_action_pressed("drift")
	drift_direction = sign(steer_input) if is_drifting else 0

	_update_rear_lights_and_surface2(is_reversing, is_drifting)

	if is_drifting:
		var drift_force_vector = -transform.basis.x * drift_direction * DRIFT_STRENGTH * delta
		apply_central_force(drift_force_vector)

		if linear_velocity.length() > DRIFT_MIN_SPEED:
			var speed_dir = linear_velocity.normalized()
			var deceleration_force = -speed_dir * DRIFT_DECELERATION * delta
			apply_central_force(deceleration_force)
		steering = move_toward(steering, drift_direction * MAX_STEER * 0.5, delta * 1.0)
	else:
		steering = move_toward(steering, steer_input * MAX_STEER, delta * 2.5)

	engine_force = move_input * ENGINE_POWER * int(engine_on)

	camera_pivot.global_position = camera_pivot.global_position.lerp(global_position, delta * CAMERA_LERP_SPEED)
	camera_pivot.transform = camera_pivot.transform.interpolate_with(transform, delta * CAMERA_TRANSFORM_LERP_SPEED)

	look_at = look_at.lerp(global_position + linear_velocity, delta * 5.0)
	camera_3d.look_at(look_at)
	reverse_camera.look_at(look_at)

	_check_camera_switch()

	var speed_kph = linear_velocity.length() * 3.6
	displayed_speed = lerp(displayed_speed, speed_kph, delta * 5)
	var color_tag = _get_speed_color_tag(displayed_speed)
	speed_label.text = "[color=#" + color_tag + "]" + str(round(displayed_speed)) + "[/color] км ч"
	speed_label.bbcode_enabled = true
	
	speedometer_ui.visible = engine_on
	stamina_bar.visible = engine_on

	if radio_ui.visible:
		track_display_timer += delta
		if track_display_timer >= track_display_time:
			radio_ui.visible = false
			track_display_timer = 0.0

	handle_nitro_boost(delta)
	update_stamina_ui()

	_check_for_flip(delta)

	if flip_timer.is_stopped() == false and timer_ui.visible:
		_update_timer_label()

	var is_drifting_condition = Input.is_action_pressed("drift") and speed_kph > 10
	if is_drifting_condition:
		if not drift_sound.playing:
			drift_sound.play()
	elif drift_sound.playing:
		drift_sound.stop()

	var is_accelerating_condition = (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or is_boosting) and engine_on
	if is_accelerating_condition:
		if not driving_sound.playing:
			driving_sound.play()
	elif driving_sound.playing:
		driving_sound.stop()

	var is_idle_condition = engine_on and not (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or is_boosting)
	if is_idle_condition:
		if not idle_sound.playing:
			idle_sound.play()
	elif idle_sound.playing:
		idle_sound.stop()

	if is_boosting and not was_boosting and engine_on:
		nos_sound.play()
	was_boosting = is_boosting

func _input(event):
	if event.is_action_pressed("Next"):
		play_next_track()
	elif event.is_action_pressed("Last"):
		play_previous_track()
	elif event.is_action_pressed("stop_music"):
		if radio.playing:
			radio.stop()

	if event.is_action_pressed("switch_cameras"):
		_toggle_camera_cycle()

	if event.is_action_pressed("ui_accept"):
		reset_flip_timer()

	if event.is_action_pressed("toggle_headlights"):
		headlights_on = !headlights_on
		front_left_light.visible = headlights_on
		front_right_light.visible = headlights_on
		_update_surface_colors()

	if event.is_action_pressed("f"):
		engine_on = !engine_on
		if engine_on:
			engine_start_sound.play()
			engine_status_label.text = "Двигатель запущен"
			engine_status_label.modulate = Color.GREEN
		else:
			engine_status_label.text = "Двигатель выключен"
			engine_status_label.modulate = Color.RED
		engine_status_ui.visible = true
		get_tree().create_timer(2.0).connect("timeout", Callable(engine_status_ui, "set_visible").bind(false))

func _check_camera_switch():
	var manual_camera_active = false

	if not camera_cycle_active:
		if Input.is_action_pressed("left_camera_view"):
			_activate_camera(left_camera)
			manual_camera_active = true
		elif Input.is_action_pressed("right_camera_view"):
			_activate_camera(right_camera)
			manual_camera_active = true

	if not manual_camera_active and not camera_cycle_active:
		var forward_speed = linear_velocity.dot(transform.basis.z)
		var threshold = 0.1

		if forward_speed > threshold:
			_activate_camera(camera_3d)
		elif forward_speed < -threshold:
			_activate_camera(reverse_camera)
		else:
			_activate_camera(camera_3d)

func _toggle_camera_cycle():
	camera_cycle_active = !camera_cycle_active
	if camera_cycle_active:
		current_camera_index = 0
		_switch_to_next_camera()
		camera_timer.start()
	else:
		camera_timer.stop()
		_check_camera_switch()

func _switch_to_next_camera():
	current_camera_index = (current_camera_index + 1) % cameras.size()
	_activate_camera(cameras[current_camera_index])

func _activate_camera(camera: Camera3D):
	camera_3d.current = (camera == camera_3d)
	reverse_camera.current = (camera == reverse_camera)
	left_camera.current = (camera == left_camera)
	right_camera.current = (camera == right_camera)
	x1_camera.current = (camera == x1_camera)
	x2_camera.current = (camera == x2_camera)
	x3_camera.current = (camera == x3_camera)

func load_music_files():
	var dir = DirAccess.open(MUSIC_PATH)
	if dir == null:
		printerr("Failed to open directory: ", MUSIC_PATH)
		return

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if not dir.current_is_dir():
			var full_path = MUSIC_PATH + filename
			if full_path.get_extension().to_lower() in ["ogg", "wav", "mp3"]:
				music_files.append(full_path)
		filename = dir.get_next()
	dir.list_dir_end()

	music_files.shuffle()

func play_current_track():
	if music_files.size() == 0:
		return

	var track_path = music_files[current_track_index]
	var stream = load(track_path) as AudioStream
	if stream == null:
		printerr("Failed to load track: ", track_path)
		return
	radio.stream = stream
	radio.play()
	display_track_name(track_path.get_file().get_basename())

func play_next_track():
	current_track_index = (current_track_index + 1) % music_files.size()
	play_current_track()

func play_previous_track():
	current_track_index = (current_track_index - 1 + music_files.size()) % music_files.size()
	play_current_track()

func display_track_name(track_name: String):
	track_name_label.text = track_name
	radio_ui.visible = true
	track_display_timer = 0.0

func handle_nitro_boost(delta):
	if Input.is_action_pressed("boost") and not is_recharging and engine_on:
		if current_stamina > 0:
			activate_boost(true)
			current_stamina = max(current_stamina - stamina_depletion_rate * delta, 0)
		else:
			deactivate_boost()
			start_recharge()
	else:
		deactivate_boost()
		if not is_recharging:
			current_stamina = min(current_stamina + stamina_regen_rate * delta, max_stamina)

func activate_boost(enable: bool):
	is_boosting = enable
	engine_force = ENGINE_POWER * (2.0 if enable else 1.0)
	blur_effect.visible = enable

func deactivate_boost():
	if is_boosting:
		engine_force = ENGINE_POWER
		blur_effect.visible = false
		is_boosting = false

func start_recharge():
	is_recharging = true
	stamina_timer.start()

func update_stamina_ui():
	stamina_bar.value = current_stamina

func _flip_car():
	rotation = Vector3(0, 0, 0)
	linear_velocity = Vector3(0, 0, 0)
	angular_velocity = Vector3(0, 0, 0)
	is_flipped = false
	timer_ui.visible = false

func _check_for_flip(delta):
	var up_vector = transform.basis.y
	var world_up = Vector3(0, 1, 0)
	var angle = acos(up_vector.dot(world_up))
	var angle_degrees = rad_to_deg(angle)

	if angle_degrees > MAX_ROLL_ANGLE and not is_flipped:
		is_flipped = true
		start_flip_timer()
	elif angle_degrees < MAX_ROLL_ANGLE:
		reset_flip_timer()

func start_flip_timer():
	is_flipped = true
	ui_delay_timer.start()

func _show_timer_ui():
	timer_ui.visible = true
	flip_timer.start()
	_update_timer_label()

func reset_flip_timer():
	if is_flipped:
		is_flipped = false
		timer_ui.visible = false
		flip_timer.stop()
		ui_delay_timer.stop()

func _update_timer_label():
	var remaining_time = flip_timer.time_left
	timer_label.text = "Вы перевернётесь через " + str(round(remaining_time))

func _on_stamina_timer_timeout():
	is_recharging = false

func _get_speed_color_tag(speed):
	if speed < 100:
		return "00ff00"
	elif speed < 200:
		return "ffff00"
	else:
		return "ff0000"

func _update_surface_colors():
	var color = YELLOW_COLOR if headlights_on else DEFAULT_COLOR
	surface4_material.albedo_color = color
	surface3_material.albedo_color = color

func _update_rear_lights_and_surface2(is_reversing: bool, is_drifting: bool):
	var is_red = is_drifting || is_reversing
	surface2_material.albedo_color = RED_COLOR if is_red else GRAY_COLOR
	rear_left_light.visible = is_red
	rear_right_light.visible = is_red
	var light_color = Color("FF0000") if is_red else Color("FFFFFF")
	rear_left_light.light_color = light_color
	rear_right_light.light_color = light_color

func _on_water_area_body_entered(body):
	if body == self:
		reset_to_respawn_point()

func reset_to_respawn_point():
	global_transform.origin = respawn_point
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	rotation = Vector3.ZERO
