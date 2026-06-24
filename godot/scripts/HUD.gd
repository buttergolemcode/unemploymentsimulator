# HUD.gd — In-game HUD overlay (money, heat, day, reputation, actions)
extends CanvasLayer

@onready var money_label: Label = $MarginContainer/VBoxContainer/StatsBar/HBoxContainer/MoneyValue
@onready var heat_label: Label = $MarginContainer/VBoxContainer/StatsBar/HBoxContainer/HeatValue
@onready var day_label: Label = $MarginContainer/VBoxContainer/StatsBar/HBoxContainer/DayValue
@onready var rep_label: Label = $MarginContainer/VBoxContainer/StatsBar/HBoxContainer/RepValue
@onready var actions_label: Label = $MarginContainer/VBoxContainer/StatsBar/HBoxContainer/ActionsValue

@onready var log_container: VBoxContainer = $MarginContainer/VBoxContainer2/ScrollContainer/LogContainer
@onready var end_day_button: Button = $EndDayButton

func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.heat_changed.connect(_on_heat_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.actions_changed.connect(_on_actions_changed)
	GameManager.reputation_changed.connect(_on_rep_changed)
	GameManager.log_message.connect(_on_log_message)
	GameManager.phase_changed.connect(_on_phase_changed)
	
	# Initial values
	_on_money_changed(GameManager.money)
	_on_heat_changed(GameManager.heat)
	_on_day_changed(GameManager.day)
	_on_actions_changed(GameManager.actions_left, GameManager.MAX_ACTIONS)
	_on_rep_changed(GameManager.reputation)

func _on_money_changed(amount: float) -> void:
	money_label.text = GameManager.format_money(amount)

func _on_heat_changed(amount: float) -> void:
	heat_label.text = "%d/100" % int(amount)
	# Color based on heat level
	if amount >= 80:
		heat_label.add_theme_color_override("font_color", Color.RED)
	elif amount >= 50:
		heat_label.add_theme_color_override("font_color", Color.ORANGE)
	elif amount >= 25:
		heat_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		heat_label.add_theme_color_override("font_color", Color.GREEN)

func _on_day_changed(d: int) -> void:
	day_label.text = str(d)

func _on_actions_changed(left: int, max_val: int) -> void:
	actions_label.text = "%d/%d" % [left, max_val]
	end_day_button.text = "End Day" if left == 0 else "Sleep Early"
	end_day_button.disabled = left > 0 and left < max_val

func _on_rep_changed(amount: float) -> void:
	rep_label.text = "%d/100" % int(amount)

func _on_log_message(text: String, type: String) -> void:
	var label = Label.new()
	label.text = "[D%d] %s" % [GameManager.day, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	match type:
		"money": label.add_theme_color_override("font_color", Color("#4ade80"))
		"danger": label.add_theme_color_override("font_color", Color("#ef4444"))
		"heat": label.add_theme_color_override("font_color", Color("#fb923c"))
		"event": label.add_theme_color_override("font_color", Color("#a855f7"))
		"success": label.add_theme_color_override("font_color", Color("#22c55e"))
		_: label.add_theme_color_override("font_color", Color("#94a3b8"))
	
	log_container.add_child(label)
	
	# Keep only last 30 entries
	while log_container.get_child_count() > 30:
		log_container.get_child(0).queue_free()
	
	# Auto-scroll to bottom
	await get_tree().process_frame
	var scroll = $MarginContainer/VBoxContainer2/ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "menu":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif new_phase == "won" or new_phase == "lost":
		get_tree().change_scene_to_file("res://scenes/EndScreen.tscn")

func _on_end_day_button_pressed() -> void:
	if GameManager.actions_left > 0:
		# Confirm
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "End the day early? You have actions left."
		dialog.confirmed.connect(func(): GameManager.end_day())
		add_child(dialog)
		dialog.popup_centered()
	else:
		GameManager.end_day()
