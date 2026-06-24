# EventModal.gd — Random event dialog with choices
extends Control

var event_title: Label
var event_desc: Label
var choices_container: VBoxContainer

func _ready() -> void:
	var panel = Panel.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(PRESET_CENTER)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(550, 0)
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	event_title = Label.new()
	event_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(event_title)
	
	event_desc = Label.new()
	event_desc.add_theme_font_size_override("font_size", 14)
	event_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(event_desc)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	choices_container = VBoxContainer.new()
	choices_container.add_theme_constant_override("separation", 8)
	vbox.add_child(choices_container)
	
	visible = false
	GameManager.phase_changed.connect(_on_phase_changed)

func _make_panel_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.14, 0.97)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.3, 0.7, 0.8)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

func show_event(event: Dictionary) -> void:
	event_title.text = "📰 %s" % event.get("title", "Event")
	event_desc.text = event.get("description", "")
	
	for child in choices_container.get_children():
		child.queue_free()
	
	var choices = event.get("choices", [])
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = choice.get("label", "Option %d" % (i + 1))
		btn.custom_minimum_size = Vector2(0, 45)
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func():
			GameManager.resolve_event(i)
			visible = false
		)
		choices_container.add_child(btn)
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_phase_changed(new_phase: String) -> void:
	if new_phase != "playing":
		visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
