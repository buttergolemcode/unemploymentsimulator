# AutoUpdater.gd — Simple version-check + download + restart for Godot .exe
# Place this as an Autoload singleton in project.godot
extends Node

const VERSION_URL = "https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/version.txt"
const DOWNLOAD_URL = "https://github.com/buttergolemcode/unemploymentsimulator/releases/latest/download/UnemploymentSimulator.zip"
const CURRENT_VERSION = "1.0.0"

func _ready():
	_check_for_updates()

func _check_for_updates():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_version_received)
	http.request(VERSION_URL)

func _on_version_received(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		print("[Updater] Failed to check version: ", response_code)
		return
	
	var latest_version = body.get_string_from_utf8().strip_edges()
	print("[Updater] Current: ", CURRENT_VERSION, " | Latest: ", latest_version)
	
	if _is_newer(latest_version, CURRENT_VERSION):
		_show_update_dialog(latest_version)

func _is_newer(available: String, installed: String) -> bool:
	var a = available.split(".")
	var b = installed.split(".")
	for i in range(max(a.size(), b.size())):
		var av = int(a[i]) if i < a.size() else 0
		var bv = int(b[i]) if i < b.size() else 0
		if av > bv: return true
		if av < bv: return false
	return false

func _show_update_dialog(version: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Update Available"
	dialog.dialog_text = "A new version is available: v%s\n\nYou are running v%s.\n\nPlease download the new version from GitHub." % [version, CURRENT_VERSION]
	dialog.ok_button_text = "OK"
	add_child(dialog)
	dialog.popup_centered()
