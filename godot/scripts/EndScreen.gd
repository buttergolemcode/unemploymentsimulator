# EndScreen.gd — Win/lose screen with stats
extends Control

func _ready() -> void:
	var is_win = GameManager.phase == "won"
	
	$VBoxContainer/Title.text = "YOU MADE IT" if is_win else "GAME OVER"
	$VBoxContainer/Title.add_theme_color_override("font_color", 
		Color.GREEN if is_win else Color.RED)
	
	$VBoxContainer/Flavor.text = (
		"$1,000,000 in the bank. No job. No boss. You beat the system." if is_win
		else _get_lose_text()
	)
	
	$VBoxContainer/Stats.text = "Cash: %s\nDays Survived: %d\nTotal Earned: %s\nDeals Closed: %d" % [
		GameManager.format_money(GameManager.money),
		GameManager.stats.days_survived,
		GameManager.format_money(GameManager.stats.total_earned),
		GameManager.stats.deals_closed,
	]
	
	$VBoxContainer/RestartButton.grab_focus()

func _get_lose_text() -> String:
	match GameManager.lose_reason:
		"mcdonalds": return "You put on the uniform. You smell like fries forever."
		"arrested": return "Federal agents kicked your door in at 4 AM."
		"bankrupt": return "You're broke beyond recovery. McDonald's it is."
		_: return "The dream is dead."

func _on_restart_button_pressed() -> void:
	GameManager.reset_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
