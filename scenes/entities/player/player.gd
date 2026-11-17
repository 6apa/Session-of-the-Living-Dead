extends CharacterBody2D

@export var speed: float = 200.0         # Максимальная скорость (пикселей в секунду)
@export var acceleration: float = 1500.0 # Плавность разгона
@export var friction: float = 1200.0     # Плавность торможения

func _physics_process(delta: float) -> void:
	# Считываем нажатия кнопок в вектор (x, y). 
	# Если W и D нажаты, Godot сам сделает диагональ правильной длины.
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		# Если кнопки нажаты, плавно увеличиваем скорость до максимума
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
	else:
		# Если кнопки отпущены, плавно замедляемся до нуля
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# Двигаем игрока. Эта функция не даст пройти сквозь стены
	move_and_slide()
