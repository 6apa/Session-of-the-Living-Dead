extends CharacterBody2D

@export var speed: float = 75.0 # Зомби медленнее игрока
var player: CharacterBody2D
var health: int = 40

func _ready() -> void:
	# Ищем игрока на сцене (он должен быть в группе "player")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player != null:
		# Вектор направления от зомби к игроку
		var direction = global_position.direction_to(player.global_position)
		# Двигаемся в сторону игрока
		velocity = direction * speed
		move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	print("Зомби ранен! Осталось HP: ", health) # Пока просто пишем в консоль
	if health <= 0:
		queue_free() # Удаляем зомби со сцены
