extends Node3D

@export var day_night_cycle_duration: float = 360.0
@export var min_light_energy: float = 0.0
@export var max_light_energy: float = 1.0

@export var night_duration: float = 0.5
@export var transition_smoothness: float = 3.0

@export var morning_fog_color: Color = Color("#e85341")
@export var night_fog_color: Color = Color.BLACK
@export var fog_density: float = 0.01
@export var max_fog_density: float = 0.1

@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var environment: WorldEnvironment = $WorldEnvironment

var time_progress: float = 0.0
var current_light_factor: float = 0.0

func _ready():
	var env = environment.environment
	env.fog_enabled = true
	env.fog_density = fog_density
	env.fog_height = 0.0
	time_progress = (1.0 - night_duration) / 2.0
	

func _process(delta):
	time_progress += delta / day_night_cycle_duration
	time_progress = wrapf(time_progress, 0.0, 1.0)
	update_light()
	update_fog()

func update_light():
	var day_part = 1.0 - night_duration
	var day_start = night_duration / 2
	var sunset_start = day_start + day_part

	var raw_light_factor: float
	if time_progress < day_start:
		raw_light_factor = time_progress / day_start
	elif time_progress < sunset_start:
		raw_light_factor = 1.0
	else:
		raw_light_factor = 1.0 - (time_progress - sunset_start) / (1.0 - sunset_start)
	
	raw_light_factor = clamp(raw_light_factor, 0.0, 1.0)
	current_light_factor = pow(raw_light_factor, transition_smoothness)
	sun_light.light_energy = lerp(min_light_energy, max_light_energy, current_light_factor)

func update_fog():
	var env = environment.environment
	var fog_blend = 1.0 - current_light_factor
	
	var color_blend = smoothstep(0.0, 0.5, fog_blend)
	var density_blend = smoothstep(0.5, 1.0, fog_blend)
	
	env.fog_light_color = morning_fog_color.lerp(night_fog_color, color_blend)
	env.fog_density = lerp(fog_density, max_fog_density, density_blend)
