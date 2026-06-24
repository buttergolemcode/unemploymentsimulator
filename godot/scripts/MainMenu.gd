# MainMenu.gd — Main menu + controls + start game
extends Control

func _ready() -> void:
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed() -> void:
	GameManager.start_game()
	# Switch to game scene
	get_tree().change_scene_to_file("res://scenes/GameScene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
