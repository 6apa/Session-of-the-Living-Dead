extends Control

@export var game_scene: PackedScene
@export var repo_owner: String = "6apa"
@export var repo_name: String = "Session-of-the-Living-Dead"

const AUTHOR_LABELS := {
	"S1dorok": "Vladimir Sidorov (S1dorok)",
	"6apa": "Бара (6apa)"
}

# Запасные значения, если GitHub API недоступен или вернул ошибку (например, 403 rate limit)
const FALLBACK_CONTRIBUTORS := [
	{"label": "Vladimir Sidorov (S1dorok)", "commits": 1},
	{"label": "Бара (6apa)", "commits": 1}
]

@onready var menu_buttons_box: VBoxContainer = $VBoxContainer
@onready var continue_btn: Button = $VBoxContainer/Продолжить
@onready var new_game_btn: Button = $"VBoxContainer/Новая игра"
@onready var load_btn: Button = $VBoxContainer/Загрузить
@onready var settings_btn: Button = $VBoxContainer/Настройки
@onready var credits_btn: Button = $"VBoxContainer/Об авторах"
@onready var quit_btn: Button = $VBoxContainer/Выход

@onready var http_request: HTTPRequest = get_node_or_null("ContributorsRequest")
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var credits_label: RichTextLabel = $CreditsPanel/CreditsText
@onready var back_btn: Button = get_node_or_null("CreditsPanel/BackButton")
@onready var start_sound: AudioStreamPlayer2D = get_node_or_null("StartGameSound")

var _stats_loaded: bool = false
var _is_starting_game: bool = false

func _ready() -> void:
	continue_btn.disabled = true
	credits_panel.visible = false
	menu_buttons_box.visible = true

	if credits_label:
		credits_label.bbcode_enabled = true

	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_btn.pressed.connect(_on_placeholder_pressed.bind("Загрузить"))
	settings_btn.pressed.connect(_on_placeholder_pressed.bind("Настройки"))
	credits_btn.pressed.connect(_on_credits_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	if back_btn:
		back_btn.pressed.connect(_close_credits)

	if http_request:
		http_request.request_completed.connect(_on_contributors_request_completed)

func _unhandled_input(event: InputEvent) -> void:
	if credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_credits()
		accept_event()

func _on_new_game_pressed() -> void:
	if _is_starting_game:
		return

	if not game_scene:
		push_warning("Не указана сцена game_scene в инспекторе MainMenu!")
		return

	_is_starting_game = true
	new_game_btn.disabled = true

	if start_sound and start_sound.stream:
		_play_detached_sound(start_sound)

	await get_tree().create_timer(0.5, true, false, true).timeout
	get_tree().change_scene_to_packed(game_scene)

func _play_detached_sound(player: AudioStreamPlayer2D) -> void:
	var detached := AudioStreamPlayer2D.new()
	detached.stream = player.stream
	detached.bus = player.bus
	detached.volume_db = player.volume_db
	detached.pitch_scale = player.pitch_scale
	detached.global_position = player.global_position

	get_tree().root.add_child(detached)
	detached.play()
	detached.finished.connect(detached.queue_free)

func _on_placeholder_pressed(section_name: String) -> void:
	print("Открыт раздел: ", section_name)

func _on_credits_pressed() -> void:
	menu_buttons_box.visible = false
	credits_panel.visible = true
	if _stats_loaded:
		return

	credits_label.text = "[font_size=24]Загрузка...[/font_size]"
	if not http_request:
		push_warning("Узел ContributorsRequest не найден — используем запасную статистику.")
		_show_fallback_credits()
		return

	var url := "https://api.github.com/repos/%s/%s/contributors" % [repo_owner, repo_name]
	var headers := [
		"User-Agent: Godot-Game-Client",
		"Accept: application/vnd.github+json"
	]
	var err := http_request.request(url, headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_warning("Ошибка запуска HTTPRequest (%s) — используем запасную статистику." % err)
		_show_fallback_credits()

func _close_credits() -> void:
	credits_panel.visible = false
	menu_buttons_box.visible = true

func _on_contributors_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_warning("GitHub API вернул result=%s, code=%s — используем запасную статистику." % [result, response_code])
		_show_fallback_credits()
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or typeof(json.data) != TYPE_ARRAY:
		push_warning("Не удалось распарсить JSON от GitHub API — используем запасную статистику.")
		_show_fallback_credits()
		return

	var contributors: Array = json.data
	if contributors.is_empty():
		_show_fallback_credits()
		return

	var total_commits := 0
	for entry in contributors:
		if typeof(entry) == TYPE_DICTIONARY:
			total_commits += int(entry.get("contributions", 0))

	if total_commits <= 0:
		_show_fallback_credits()
		return

	var lines: PackedStringArray = ["[font_size=28][b]Вклад в проект[/b][/font_size]\n"]
	for entry in contributors:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var login := str(entry.get("login", "unknown"))
		var commits := int(entry.get("contributions", 0))
		var share := (float(commits) / float(total_commits)) * 100.0
		var label := str(AUTHOR_LABELS.get(login, login))
		lines.append("[font_size=24]• %s — %.1f%%[/font_size]" % [label, share])

	credits_label.text = "\n".join(lines)
	_stats_loaded = true

func _show_fallback_credits() -> void:
	var total := 0
	for item in FALLBACK_CONTRIBUTORS:
		total += int(item.get("commits", 0))

	var lines: PackedStringArray = ["[font_size=28][b]Вклад в проект[/b][/font_size]\n"]
	for item in FALLBACK_CONTRIBUTORS:
		var label := str(item.get("label", "Автор"))
		var commits := int(item.get("commits", 0))
		var share := (float(commits) / float(max(total, 1))) * 100.0
		lines.append("[font_size=24]• %s — %.1f%%[/font_size]" % [label, share])

	credits_label.text = "\n".join(lines)
	_stats_loaded = true

func _on_quit_pressed() -> void:
	get_tree().quit()
