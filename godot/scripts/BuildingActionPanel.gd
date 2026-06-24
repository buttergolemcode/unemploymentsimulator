# BuildingActionPanel.gd — Modal panel shown when entering a scheme building
# Shows scheme info + available actions with Run buttons
extends Control

var current_scheme_id: String = ""
var actions_container: VBoxContainer
var scheme_title: Label
var scheme_desc: Label
var skill_label: Label
var close_button: Button

func _ready() -> void:
	# Build UI
	var panel = Panel.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_CENTER)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(600, 0)
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header
	scheme_title = Label.new()
	scheme_title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(scheme_title)
	
	scheme_desc = Label.new()
	scheme_desc.add_theme_font_size_override("font_size", 14)
	scheme_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(scheme_desc)
	
	skill_label = Label.new()
	skill_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(skill_label)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# Actions container
	actions_container = VBoxContainer.new()
	actions_container.add_theme_constant_override("separation", 8)
	vbox.add_child(actions_container)
	
	# Close button
	close_button = Button.new()
	close_button.text = "Exit Building (Esc)"
	close_button.custom_minimum_size = Vector2(0, 40)
	close_button.add_theme_font_size_override("font_size", 16)
	vbox.add_child(close_button)
	close_button.pressed.connect(_on_close)
	
	# Initially hidden
	visible = false

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.4, 0.5, 0.8)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func show_panel(scheme_id: String) -> void:
	current_scheme_id = scheme_id
	var scheme = SchemeData.get_scheme(scheme_id)
	
	scheme_title.text = "%s %s" % [scheme.get("emoji", ""), scheme.get("name", "Unknown")]
	scheme_desc.text = scheme.get("description", "")
	
	var skill_level = GameManager.skills.get(scheme_id, 1)
	var skill_xp = GameManager.skill_xp.get(scheme_id, 0)
	skill_label.text = "Skill: Lv.%d (%d/100 XP) — %s heat" % [
		skill_level, skill_xp, scheme.get("heat_risk", "unknown").to_upper()
	]
	
	# Clear old actions
	for child in actions_container.get_children():
		child.queue_free()
	
	# Add actions
	var actions = SchemeData.get_actions(scheme_id)
	for action in actions:
		var action_card = _make_action_card(action)
		actions_container.add_child(action_card)
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _make_action_card(action: Dictionary) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 80)
	
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.13, 0.18, 1)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.25, 0.3, 0.4, 0.6)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", card_style)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 16)
	hbox.offset_left = 12
	hbox.offset_top = 8
	hbox.offset_right = -12
	hbox.offset_bottom = -8
	card.add_child(hbox)
	
	# Left: label + description
	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 4)
	hbox.add_child(info_box)
	
	var name_label = Label.new()
	name_label.text = action.get("label", "Unknown")
	name_label.add_theme_font_size_override("font_size", 15)
	info_box.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = "%s — %d action(s)" % [action.get("description", ""), action.get("cost", 1)]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(desc_label)
	
	# Check availability
	var is_available = true
	if action.has("available"):
		is_available = action.available.call(GameManager)
	
	if not is_available:
		desc_label.text += "\n" + action.get("unavailable_reason", "Not available")
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	
	# Right: Run button
	var run_button = Button.new()
	run_button.text = "Run"
	run_button.custom_minimum_size = Vector2(80, 40)
	run_button.add_theme_font_size_override("font_size", 14)
	run_button.disabled = not is_available or GameManager.actions_left < action.get("cost", 1)
	hbox.add_child(run_button)
	
	run_button.pressed.connect(func():
		_run_action(action)
	)
	
	return card

func _run_action(action: Dictionary) -> void:
	var result = GameManager.perform_action(current_scheme_id, action.id)
	
	if result.success:
		# Refresh the panel to update action states
		show_panel(current_scheme_id)
	
	# If game ended, close panel
	if GameManager.phase != "playing":
		visible = false

func _on_close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_scheme_id = ""

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()
