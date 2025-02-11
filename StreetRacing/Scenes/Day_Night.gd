extends Node

@export var day_color: Color = Color(1, 0.733, 0.0, 1)  # Теплый оранжевый цвет для дня
@export var night_color: Color = Color(0, 0, 0, 1)  # Черный цвет для ночи
@export var transition_duration: float = 10.0  # Продолжительность перехода в секундах
@export var directional_light: DirectionalLight3D
@export var platform_material: Material  # Материал платформы (например, StandardMaterial3D)

var world_environment: WorldEnvironment
var current_time: float = 0.0
var is_day: bool = true

func _ready():
	# Получаем WorldEnvironment из дерева сцены
	world_environment = get_node("WorldEnvironment")

	if world_environment == null:
		printerr("WorldEnvironment не найден! Убедитесь, что у вас есть узел WorldEnvironment в вашей сцене.")

	if directional_light == null:
		printerr("DirectionalLight3D не найден! Убедитесь, что у вас есть узел DirectionalLight3D в вашей сцене.")

	if platform_material == null:
		printerr("Материал платформы не найден! Убедитесь, что вы назначили материал для platform_material.")

func _process(delta):
	# Увеличиваем время
	current_time += delta

	# Вычисляем коэффициент для интерполяции цвета
	var t: float = sin(current_time / transition_duration)
	t = abs(t) # Преобразуем sin в положительные значения от 0 до 1

	# Выполняем интерполяцию цвета фона
	if world_environment != null:
		world_environment.environment.background_color = day_color.lerp(night_color, t)

		# Влияем на энергию DirectionalLight3D
		if directional_light != null:
			directional_light.light_energy = lerp(1.0, 0.1, t) # Уменьшаем энергию света ночью

		# Влияем на параметры тумана
		world_environment.environment.fog_light_color = day_color.lerp(night_color, t)
		
		# Влияем на цвет платформы
		if platform_material != null:
			# Изменяем ambient_color материала платформы
			if platform_material is StandardMaterial3D: # Проверяем, является ли материал StandardMaterial3D
				platform_material.albedo_color = Color(1, 1, 1, 1).lerp(Color(0.2, 0.2, 0.2, 1), t) # Приглушаем цвет albedo
				platform_material.ambient_color = Color(1, 1, 1, 1).lerp(Color(0, 0, 0, 1), t) # Приглушаем ambient color
			else:
				printerr("Материал платформы должен быть StandardMaterial3D для изменения ambient_color.")
