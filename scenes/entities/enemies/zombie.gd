extends CharacterBody2D

@export var speed: float = 80.0 
@export var attack_range: float = 125.0 # Увеличили дистанцию
@export var damage: int = 10           
@export var attack_cooldown: float = 1.5

var player: CharacterBody2D
var health: int = 40
var can_attack: bool = true
var knockback_force: float = 150.0 # Сила отскока

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player != null:
		var distance = global_position.distance_to(player.global_position)
		
		if distance > attack_range:
			# Идем к игроку
			var direction = global_position.direction_to(player.global_position)
			velocity = direction * speed
		else:
			# Стоим на месте
			velocity = Vector2.ZERO 
			
			# Если можем атаковать
			if can_attack:
				attack()
		
		# Применяем отскок (если он есть)
		if velocity != Vector2.ZERO:
			move_and_slide()
		else:
			# Если стоим, но нас толкнули — плавно тормозим
			velocity = velocity.move_toward(Vector2.ZERO, 1000 * delta)
			move_and_slide()

func attack() -> void:
	can_attack = false
	print("Зомби укусил игрока!")
	
	if player.has_method("take_damage"):
		player.take_damage(damage)
		
	# Отталкиваем зомби назад от игрока
	var knockback_dir = global_position.direction_to(player.global_position) * -1
	velocity = knockback_dir * knockback_force
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: int) -> void:
	health -= amount
	print("Зомби ранен! Осталось HP: ", health)
	if health <= 0:
		queue_free()
