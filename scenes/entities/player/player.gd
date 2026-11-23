extends CharacterBody2D

@export var speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0
@export var attack_damage: int = 15
@export var max_health: int = 100

var current_health: int
var can_attack: bool = true

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	hitbox.monitoring = false # Хитбокс выключен по умолчанию

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, acceleration * delta)
		if input_dir.x != 0:
			scale.x = sign(input_dir.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		
	move_and_slide()
	
	# Проверка атаки (из прошлого этапа)
	if Input.is_action_just_pressed("attack_light") and can_attack:
		attack()

func attack() -> void:
	can_attack = false
	print("Удар!")
	
	hitbox.monitoring = true
	await get_tree().create_timer(0.1).timeout
	
	var bodies = hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage"):
			body.take_damage(attack_damage)
			
	hitbox.monitoring = false
	await get_tree().create_timer(0.3).timeout
	can_attack = true

# --- НОВОЕ: Получение урона ---
func take_damage(amount: int) -> void:
	current_health -= amount
	print("Игрок ранен! Здоровье: ", current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	print("Игрок погиб!")
	# Пока просто перезапускаем игру
	get_tree().reload_current_scene()
