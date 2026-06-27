# BuildingActionPanel.gd — Modal panel for scheme actions (built in code)
extends Control

var current_scheme_id: String = ""
var panel: Panel
var title_label: Label
var desc_label: Label
var skill_label: Label
var actions_container: VBoxContainer

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)
	
	# Panel
	panel = Panel.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.custom_minimum_size = Vector2(650, 0)
	panel.position = Vector2(-325, -300)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.14, 0.98)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.4, 0.5, 0.8)
	style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12; style.corner_radius_bottom_right = 12
	style.content_margin_left = 24; style.content_margin_right = 24
	style.content_margin_top = 20; style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title_label)
	
	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	skill_label = Label.new()
	skill_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(skill_label)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	actions_container = VBoxContainer.new()
	actions_container.add_theme_constant_override("separation", 6)
	vbox.add_child(actions_container)
	
	var close_btn = Button.new()
	close_btn.text = "Exit Building (Esc)"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.add_theme_font_size_override("font_size", 16)
	vbox.add_child(close_btn)
	close_btn.pressed.connect(_on_close)

func show_panel(scheme_id: String) -> void:
	current_scheme_id = scheme_id
	var scheme = SchemeData.get_scheme(scheme_id)
	title_label.text = "%s %s" % [scheme.get("emoji", ""), scheme.get("name", "?")]
	desc_label.text = scheme.get("description", "")
	var sl = GameManager.skills.get(scheme_id, 1)
	var sx = GameManager.skill_xp.get(scheme_id, 0)
	skill_label.text = "Skill: Lv.%d (%d/100 XP) — %s HEAT" % [sl, sx, scheme.get("heat_risk", "?").to_upper()]
	
	for child in actions_container.get_children():
		child.queue_free()
	
	var actions = SchemeData.get_actions(scheme_id)
	for action in actions:
		actions_container.add_child(_make_action_card(action))
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _make_action_card(action: Dictionary) -> Control:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(0, 70)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.12, 0.13, 0.18, 1)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_color = Color(0.25, 0.3, 0.4, 0.5)
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	card.add_theme_stylebox_override("panel", s)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(PRESET_FULL_RECT)
	hbox.offset_left = 10; hbox.offset_top = 6
	hbox.offset_right = -10; hbox.offset_bottom = -6
	hbox.add_theme_constant_override("separation", 12)
	card.add_child(hbox)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	hbox.add_child(info)
	
	var name_lbl = Label.new()
	name_lbl.text = action.get("label", "?")
	name_lbl.add_theme_font_size_override("font_size", 14)
	info.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = "%s — %d action(s)" % [action.get("description", ""), action.get("cost", 1)]
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
	info.add_child(desc_lbl)
	
	var avail = SchemeData.is_action_available(GameManager, current_scheme_id, action.id)
	if not avail:
		if action.id == "setup_tax_fraud":
			desc_lbl.text += " (Already set up)"
		elif action.id == "harvest_refund":
			desc_lbl.text += " (Set up first)"
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.6, 0.2))
	
	var btn = Button.new()
	btn.text = "Run"
	btn.custom_minimum_size = Vector2(70, 36)
	btn.add_theme_font_size_override("font_size", 13)
	btn.disabled = not avail or GameManager.actions_left < action.get("cost", 1)
	hbox.add_child(btn)
	
	var action_id = action.id
	btn.pressed.connect(func():
		GameManager.perform_action(current_scheme_id, action_id)
		if GameManager.phase == "playing":
			show_panel(current_scheme_id)
		else:
			visible = false
	)
	
	return card

func _on_close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_scheme_id = ""

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()
