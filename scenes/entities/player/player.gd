extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var attack_damage: int = 15
@export var max_health: int = 100

var current_health: int
var can_attack: bool = true

@onready var hitbox: Area2D = $Hitbox
# Ссылка на ноду анимации
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D 

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	hitbox.monitoring = false

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
		
		# Переменная для хранения текущего направления
		var current_anim = "walk" # По умолчанию идем вниз
		
		# Определяем, куда движется игрок (приоритет отдаем горизонтали, если нажата диагональ)
		if abs(input_dir.x) > abs(input_dir.y):
			current_anim = "walk_lr"
			# Отражаем спрайт влево, если идем влево
			if input_dir.x < 0:
				animated_sprite.scale.x = -1
			else:
				animated_sprite.scale.x = 1
		else:
			if input_dir.y < 0:
				current_anim = "walk_up"
			else:
				current_anim = "walk"
				
		# Запускаем нужную анимацию, если она еще не играет
		if animated_sprite.animation != current_anim or not animated_sprite.is_playing():
			animated_sprite.play(current_anim)
			
	else:
		# Если стоим на месте — тормозим и останавливаем анимацию
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if animated_sprite.is_playing():
			animated_sprite.stop()
		
	move_and_slide()
	
	# Логика атаки
	if Input.is_action_just_pressed("attack_light") and can_attack:
		attack()

func attack() -> void:
	can_attack = false
	print("Удар!")
	
	hitbox.monitoring = true
	await get_tree().create_timer(0.1).timeout
	
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		# ВАЖНО: Проверяем, что это не сам игрок и у цели есть метод take_damage
		if body != self and body.has_method("take_damage"):
			body.take_damage(attack_damage)
			
	hitbox.monitoring = false
	await get_tree().create_timer(0.3).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	current_health -= amount
	print("Игрок ранен! Здоровье: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	print("Игрок погиб!")
	get_tree().reload_current_scene()
