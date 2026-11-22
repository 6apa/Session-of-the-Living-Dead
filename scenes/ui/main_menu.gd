extends Control

@export var game_scene: PackedScene

@onready var continue_btn: Button = $VBoxContainer/Продолжить
@onready var new_game_btn: Button = $"VBoxContainer/Новая игра"
@onready var load_btn: Button = $VBoxContainer/Загрузить
@onready var settings_btn: Button = $VBoxContainer/Настройки
@onready var credits_btn: Button = $"VBoxContainer/Об авторах"
@onready var quit_btn: Button = $VBoxContainer/Выход

func _ready() -> void:
	# Пока сохранений нет, делаем "Продолжить" неактивной
	continue_btn.disabled = true

	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_btn.pressed.connect(_on_placeholder_pressed.bind("Загрузить"))
	settings_btn.pressed.connect(_on_placeholder_pressed.bind("Настройки"))
	credits_btn.pressed.connect(_on_placeholder_pressed.bind("Об авторах"))
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_new_game_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		push_warning("Не указана сцена game_scene в инспекторе MainMenu!")

func _on_placeholder_pressed(section_name: String) -> void:
	print("Открыт раздел: ", section_name)

func _on_quit_pressed() -> void:
	get_tree().quit()
