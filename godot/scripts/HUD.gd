# HUD.gd — In-game HUD (built entirely in code, no scene dependencies)
extends CanvasLayer

var money_label: Label
var heat_label: Label
var day_label: Label
var rep_label: Label
var actions_label: Label
var log_container: VBoxContainer
var end_day_button: Button
var interact_hint: Label

func _ready() -> void:
	_build_ui()
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.heat_changed.connect(_on_heat_changed)
	GameManager.day_changed.connect(_on_day_changed)
	GameManager.actions_changed.connect(_on_actions_changed)
	GameManager.reputation_changed.connect(_on_rep_changed)
	GameManager.log_message.connect(_on_log_message)
	GameManager.phase_changed.connect(_on_phase_changed)
	_on_money_changed(GameManager.money)
	_on_heat_changed(GameManager.heat)
	_on_day_changed(GameManager.day)
	_on_actions_changed(GameManager.actions_left, GameManager.MAX_ACTIONS)
	_on_rep_changed(GameManager.reputation)

func _build_ui() -> void:
	# Stats bar (top-left)
	var top_bar = HBoxContainer.new()
	top_bar.position = Vector2(10, 10)
	top_bar.add_theme_constant_override("separation", 30)
	add_child(top_bar)
	
	money_label = _make_label("$500", 20)
	heat_label = _make_label("0/100", 20)
	day_label = _make_label("1", 20)
	actions_label = _make_label("3/3", 20)
	rep_label = _make_label("0/100", 20)
	
	top_bar.add_child(_make_stat_pair("Cash", money_label))
	top_bar.add_child(_make_stat_pair("Heat", heat_label))
	top_bar.add_child(_make_stat_pair("Day", day_label))
	top_bar.add_child(_make_stat_pair("Actions", actions_label))
	top_bar.add_child(_make_stat_pair("Rep", rep_label))
	
	# Interaction hint (center-bottom)
	interact_hint = Label.new()
	interact_hint.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 100, get_viewport().get_visible_rect().size.y - 100)
	interact_hint.add_theme_font_size_override("font_size", 16)
	interact_hint.add_theme_color_override("font_color", Color.YELLOW)
	interact_hint.text = ""
	add_child(interact_hint)
	
	# Log (bottom-left)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(10, get_viewport().get_visible_rect().size.y - 200)
	scroll.size = Vector2(450, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	log_container = VBoxContainer.new()
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 2)
	scroll.add_child(log_container)
	
	# End day button (bottom-center)
	end_day_button = Button.new()
	end_day_button.position = Vector2(get_viewport().get_visible_rect().size.x / 2 - 60, get_viewport().get_visible_rect().size.y - 50)
	end_day_button.size = Vector2(120, 36)
	end_day_button.text = "End Day"
	end_day_button.add_theme_font_size_override("font_size", 14)
	add_child(end_day_button)
	end_day_button.pressed.connect(_on_end_day)

func _make_label(text: String, size: int) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l

func _make_stat_pair(name: String, value_label: Label) -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var n = Label.new()
	n.text = name + ":"
	n.add_theme_font_size_override("font_size", 18)
	n.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	box.add_child(n)
	box.add_child(value_label)
	return box

func set_interact_hint(text: String) -> void:
	interact_hint.text = text

func _on_money_changed(amount: float) -> void:
	money_label.text = GameManager.format_money(amount)

func _on_heat_changed(amount: float) -> void:
	heat_label.text = "%d/100" % int(amount)
	if amount >= 80: heat_label.add_theme_color_override("font_color", Color.RED)
	elif amount >= 50: heat_label.add_theme_color_override("font_color", Color.ORANGE)
	elif amount >= 25: heat_label.add_theme_color_override("font_color", Color.YELLOW)
	else: heat_label.add_theme_color_override("font_color", Color.GREEN)

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
	label.add_theme_font_size_override("font_size", 12)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match type:
		"money": label.add_theme_color_override("font_color", Color("#4ade80"))
		"danger": label.add_theme_color_override("font_color", Color("#ef4444"))
		"heat": label.add_theme_color_override("font_color", Color("#fb923c"))
		"event": label.add_theme_color_override("font_color", Color("#a855f7"))
		"success": label.add_theme_color_override("font_color", Color("#22c55e"))
		_: label.add_theme_color_override("font_color", Color("#94a3b8"))
	log_container.add_child(label)
	while log_container.get_child_count() > 30:
		log_container.get_child(0).queue_free()

func _on_phase_changed(new_phase: String) -> void:
	if new_phase == "menu":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif new_phase == "won" or new_phase == "lost":
		get_tree().change_scene_to_file("res://scenes/EndScreen.tscn")

func _on_end_day() -> void:
	if GameManager.actions_left > 0:
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "End the day early? You have actions left."
		dialog.confirmed.connect(func(): GameManager.end_day())
		add_child(dialog)
		dialog.popup_centered()
	else:
		GameManager.end_day()
