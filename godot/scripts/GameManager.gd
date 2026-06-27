# GameManager.gd — Autoload singleton
extends Node

signal money_changed(amount: float)
signal heat_changed(amount: float)
signal day_changed(day: int)
signal actions_changed(left: int, max_val: int)
signal phase_changed(phase: String)
signal log_message(text: String, type: String)
signal reputation_changed(amount: float)
signal event_triggered(event: Dictionary)

const WIN_AMOUNT: float = 1000000.0
const MAX_ACTIONS: int = 3
const MAX_DAYS: int = 60
const STARTING_MONEY: float = 500.0

var phase: String = "menu"
var lose_reason: String = ""
var money: float = STARTING_MONEY
var day: int = 1
var actions_left: int = MAX_ACTIONS
var heat: float = 0.0
var reputation: float = 0.0
var tax_setup: bool = false
var stats: Dictionary = {}
var skills: Dictionary = {}
var skill_xp: Dictionary = {}
var pending_event: Dictionary = {}

func _init() -> void:
	_reset_state()

func _reset_state() -> void:
	phase = "menu"
	lose_reason = ""
	money = STARTING_MONEY
	day = 1
	actions_left = MAX_ACTIONS
	heat = 0.0
	reputation = 0.0
	tax_setup = false
	stats = {"total_earned": 0.0, "total_lost": 0.0, "deals_closed": 0, "days_survived": 1}
	skills = {"ecom": 1, "trading": 1, "gambling": 1, "drugs": 1, "scam": 1, "robbery": 1, "taxfraud": 1, "wirefraud": 1}
	skill_xp = {"ecom": 0, "trading": 0, "gambling": 0, "drugs": 0, "scam": 0, "robbery": 0, "taxfraud": 0, "wirefraud": 0}
	pending_event = {}

func start_game() -> void:
	_reset_state()
	phase = "playing"
	phase_changed.emit("playing")
	money_changed.emit(money)
	heat_changed.emit(heat)
	day_changed.emit(day)
	actions_changed.emit(actions_left, MAX_ACTIONS)
	log_message.emit("Welcome to the unemployment simulator. You've got $500, no job, and 60 days to hit $1,000,000.", "info")

func reset_game() -> void:
	_reset_state()
	phase_changed.emit("menu")

func perform_action(scheme_id: String, action_id: String) -> Dictionary:
	if phase != "playing":
		return {"success": false, "message": "Game not running"}
	if actions_left <= 0:
		return {"success": false, "message": "No actions left today"}
	
	var result: Dictionary = SchemeData.perform_action(self, scheme_id, action_id)
	if not result.get("success", false):
		return result
	
	money += result.get("money_delta", 0.0)
	if result.get("money_delta", 0.0) > 0:
		stats.total_earned += result.money_delta
		stats.deals_closed += 1
	elif result.get("money_delta", 0.0) < 0:
		stats.total_lost += abs(result.money_delta)
	
	heat = clamp(heat + result.get("heat_delta", 0.0), 0.0, 100.0)
	reputation = clamp(reputation + result.get("rep_delta", 0.0), 0.0, 100.0)
	
	var xp: int = result.get("xp_gain", 0)
	if xp > 0:
		_gain_xp(scheme_id, xp)
	
	actions_left -= result.get("cost", 1)
	
	if result.has("log_text"):
		log_message.emit(result.log_text, result.get("log_type", "info"))
	
	if result.get("tax_setup", false):
		tax_setup = true
	
	money_changed.emit(money)
	heat_changed.emit(heat)
	actions_changed.emit(actions_left, MAX_ACTIONS)
	reputation_changed.emit(reputation)
	
	_check_win_lose()
	
	if actions_left <= 0 and phase == "playing":
		end_day()
	
	return {"success": true}

func _gain_xp(scheme_id: String, xp: int) -> void:
	skill_xp[scheme_id] = skill_xp.get(scheme_id, 0) + xp
	while skill_xp[scheme_id] >= 100 and skills[scheme_id] < 10:
		skill_xp[scheme_id] -= 100
		skills[scheme_id] += 1
		log_message.emit("%s skill reached Level %d!" % [scheme_id.capitalize(), skills[scheme_id]], "success")

func _check_win_lose() -> void:
	if money >= WIN_AMOUNT:
		phase = "won"
		log_message.emit("$1,000,000 reached. You beat the system.", "success")
		phase_changed.emit("won")
	elif heat >= 100.0:
		phase = "lost"
		lose_reason = "arrested"
		log_message.emit("Heat hit 100. Federal agents kicked in your door.", "danger")
		phase_changed.emit("lost")
	elif money < -1000:
		phase = "lost"
		lose_reason = "bankrupt"
		log_message.emit("You're broke beyond recovery.", "danger")
		phase_changed.emit("lost")

func end_day() -> void:
	if phase != "playing":
		return
	if randf() < 0.35:
		_roll_event()
		return
	advance_day()

func advance_day() -> void:
	day += 1
	var heat_decay = max(0, 3 - int(heat / 30))
	heat = max(0, heat - heat_decay)
	actions_left = MAX_ACTIONS
	stats.days_survived = day
	
	if day > MAX_DAYS and money < 50000:
		phase = "lost"
		lose_reason = "mcdonalds"
		log_message.emit("Day %d. You walked into McDonald's." % day, "danger")
		phase_changed.emit("lost")
		return
	
	log_message.emit("Day %d. Heat cooled by %d. %d moves today." % [day, heat_decay, MAX_ACTIONS], "info")
	day_changed.emit(day)
	heat_changed.emit(heat)
	actions_changed.emit(actions_left, MAX_ACTIONS)

func _roll_event() -> void:
	var event = EventData.get_random_event(self)
	if event.is_empty():
		advance_day()
		return
	pending_event = event
	log_message.emit("EVENT: %s" % event.title, "event")
	event_triggered.emit(event)

func resolve_event(choice_index: int) -> void:
	if pending_event.is_empty():
		return
	var result: Dictionary = EventData.apply_choice(self, pending_event, choice_index)
	
	money += result.get("money_delta", 0.0)
	heat = clamp(heat + result.get("heat_delta", 0.0), 0.0, 100.0)
	reputation = clamp(reputation + result.get("rep_delta", 0.0), 0.0, 100.0)
	
	if result.has("phase"):
		phase = result.phase
		lose_reason = result.get("lose_reason", "")
		phase_changed.emit(phase)
		pending_event = {}
		return
	
	if result.has("log_entries"):
		for entry in result.log_entries:
			log_message.emit(entry.text, entry.type)
	
	money_changed.emit(money)
	heat_changed.emit(heat)
	reputation_changed.emit(reputation)
	pending_event = {}
	_check_win_lose()
	
	if phase == "playing":
		advance_day()

func rand_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

func chance(prob: float) -> bool:
	return randf() < prob

func format_money(amount: float) -> String:
	var neg = amount < 0
	var abs_val = abs(amount)
	var s: String
	if abs_val >= 1000000:
		s = "$%.2fM" % (abs_val / 1000000.0)
	elif abs_val >= 10000:
		s = "$%.1fk" % (abs_val / 1000.0)
	else:
		s = "$%d" % int(abs_val)
	return ("-" + s) if neg else s
