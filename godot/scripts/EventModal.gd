# EventModal.gd — Random event dialog (built in code)
extends Control

var panel: Panel
var title_label: Label
var desc_label: Label
var choices_container: VBoxContainer

func _ready() -> void:
	_build_ui()
	visible = false
	GameManager.event_triggered.connect(show_event)
	GameManager.phase_changed.connect(func(p): if p != "playing": visible = false)

func _build_ui() -> void:
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.7)
	add_child(overlay)
	
	panel = Panel.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.custom_minimum_size = Vector2(550, 0)
	panel.position = Vector2(-275, -250)
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.08, 0.06, 0.14, 0.98)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.5, 0.3, 0.7, 0.8)
	s.corner_radius_top_left = 12; s.corner_radius_top_right = 12
	s.corner_radius_bottom_left = 12; s.corner_radius_bottom_right = 12
	s.content_margin_left = 30; s.content_margin_right = 30
	s.content_margin_top = 24; s.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", s)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_label)
	
	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	choices_container = VBoxContainer.new()
	choices_container.add_theme_constant_override("separation", 6)
	vbox.add_child(choices_container)

func show_event(event: Dictionary) -> void:
	title_label.text = "📰 %s" % event.get("title", "Event")
	desc_label.text = event.get("description", "")
	
	for child in choices_container.get_children():
		child.queue_free()
	
	var choices = event.get("choices", [])
	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.text = choice.get("label", "Option %d" % (i + 1))
		btn.custom_minimum_size = Vector2(0, 42)
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx = i
		btn.pressed.connect(func():
			GameManager.resolve_event(idx)
			visible = false
		)
		choices_container.add_child(btn)
	
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		get_viewport().set_input_as_handled()
