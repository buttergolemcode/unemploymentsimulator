# GameManager.gd — Autoload singleton (always loaded)
# Manages game state, schemes, events, day/night cycle, win/lose conditions
extends Node

# ============================================================
# Signals
# ============================================================
signal money_changed(amount: float)
signal heat_changed(amount: float)
signal day_changed(day: int)
signal actions_changed(left: int, max_val: int)
signal phase_changed(phase: String)
signal log_message(text: String, type: String)
signal reputation_changed(amount: float)

# ============================================================
# Constants
# ============================================================
const WIN_AMOUNT: float = 1_000_000.0
const MAX_ACTIONS: int = 3
const MAX_DAYS: int = 60
const STARTING_MONEY: float = 500.0

# ============================================================
# State
# ============================================================
var phase: String = "menu"  # menu, playing, won, lost
var lose_reason: String = ""
var money: float = STARTING_MONEY
var day: int = 1
var actions_left: int = MAX_ACTIONS
var heat: float = 0.0
var reputation: float = 0.0
var tax_setup: bool = false
var stats: Dictionary = {
	"total_earned": 0.0,
	"total_lost": 0.0,
	"deals_closed": 0,
	"days_survived": 1,
}

# Skills per scheme (1-10)
var skills: Dictionary = {
	"ecom": 1, "trading": 1, "gambling": 1, "drugs": 1,
	"scam": 1, "robbery": 1, "taxfraud": 1, "wirefraud": 1,
}

# Skill XP (0-100 per skill, rolls over into level)
var skill_xp: Dictionary = {
	"ecom": 0, "trading": 0, "gambling": 0, "drugs": 0,
	"scam": 0, "robbery": 0, "taxfraud": 0, "wirefraud": 0,
}

# ============================================================
# Game lifecycle
# ============================================================
func start_game() -> void:
	phase = "playing"
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
	
	phase_changed.emit("playing")
	money_changed.emit(money)
	heat_changed.emit(heat)
	day_changed.emit(day)
	actions_changed.emit(actions_left, MAX_ACTIONS)
	log_message.emit("Welcome to the unemployment simulator. You've got $500, no job, and 60 days to hit $1,000,000. Good luck out there.", "info")

func reset_game() -> void:
	phase = "menu"
	phase_changed.emit("menu")

# ============================================================
# Action handling
# ============================================================
func perform_action(scheme_id: String, action_id: String) -> Dictionary:
	"""Perform a scheme action. Returns result dictionary."""
	if phase != "playing":
		return {"success": false, "message": "Game not running"}
	if actions_left <= 0:
		return {"success": false, "message": "No actions left today"}
	
	# Load the scheme action from data
	var action = SchemeData.get_action(scheme_id, action_id)
	if action.is_empty():
		return {"success": false, "message": "Unknown action"}
	
	# Check availability (e.g. tax fraud needs setup)
	if action.has("available") and not action.available:
		return {"success": false, "message": action.get("unavailable_reason", "Not available")}
	
	# Perform the action
	var result = action.perform.call(self)
	
	# Apply money delta
	var money_delta: float = result.get("money_delta", 0.0)
	money += money_delta
	if money_delta > 0:
		stats.total_earned += money_delta
		stats.deals_closed += 1
	elif money_delta < 0:
		stats.total_lost += abs(money_delta)
	
	# Apply heat delta
	var heat_delta: float = result.get("heat_delta", 0.0)
	heat = clamp(heat + heat_delta, 0.0, 100.0)
	
	# Apply reputation delta
	var rep_delta: float = result.get("rep_delta", 0.0)
	reputation = clamp(reputation + rep_delta, 0.0, 100.0)
	
	# Apply XP
	var xp_gain: int = result.get("xp_gain", 0)
	if xp_gain > 0:
		_gain_xp(scheme_id, xp_gain)
	
	# Consume action
	actions_left -= action.get("cost", 1)
	
	# Log
	log_message.emit(result.get("log_text", "Action performed"), result.get("log_type", "info"))
	
	# Emit signals
	money_changed.emit(money)
	heat_changed.emit(heat)
	actions_changed.emit(actions_left, MAX_ACTIONS)
	reputation_changed.emit(reputation)
	
	# Check win/lose
	_check_win_lose()
	
	# Auto-advance day if out of actions
	if actions_left <= 0 and phase == "playing":
		end_day()
	
	return {"success": true, "result": result}

func _gain_xp(scheme_id: String, xp: int) -> void:
	skill_xp[scheme_id] += xp
	while skill_xp[scheme_id] >= 100 and skills[scheme_id] < 10:
		skill_xp[scheme_id] -= 100
		skills[scheme_id] += 1
		log_message.emit("%s skill reached Level %d!" % [scheme_id.capitalize(), skills[scheme_id]], "success")

func _check_win_lose() -> void:
	if money >= WIN_AMOUNT:
		phase = "won"
		lose_reason = ""
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

# ============================================================
# Day management
# ============================================================
func end_day() -> void:
	if phase != "playing":
		return
	
	# Roll for random event (35% chance)
	if randf() < 0.35:
		_roll_event()
		return  # Event will call advance_day when resolved
	
	advance_day()

func advance_day() -> void:
	day += 1
	var heat_decay = max(0, 3 - int(heat / 30))
	heat = max(0, heat - heat_decay)
	actions_left = MAX_ACTIONS
	stats.days_survived = day
	
	# Check McDonald's pressure
	if day > MAX_DAYS and money < 50000:
		phase = "lost"
		lose_reason = "mcdonalds"
		log_message.emit("Day %d. The unemployment money ran out. You walked into McDonald's." % day, "danger")
		phase_changed.emit("lost")
		return
	
	log_message.emit("Day %d. Heat cooled by %d. %d moves today." % [day, heat_decay, MAX_ACTIONS], "info")
	day_changed.emit(day)
	heat_changed.emit(heat)
	actions_changed.emit(actions_left, MAX_ACTIONS)

# ============================================================
# Events
# ============================================================
var pending_event: Dictionary = {}

func _roll_event() -> void:
	var event = EventData.get_random_event(self)
	if event.is_empty():
		advance_day()
		return
	pending_event = event
	log_message.emit("EVENT: %s" % event.title, "event")
	# The UI will pick this up and show a dialog

func resolve_event(choice_index: int) -> void:
	if pending_event.is_empty():
		return
	var choice = pending_event.choices[choice_index]
	var result = choice.apply.call(self)
	
	var money_delta = result.get("money_delta", 0.0)
	money += money_delta
	heat = clamp(heat + result.get("heat_delta", 0.0), 0.0, 100.0)
	reputation = clamp(reputation + result.get("rep_delta", 0.0), 0.0, 100.0)
	
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

# ============================================================
# Helpers
# ============================================================
func rand_int(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

func chance(prob: float) -> bool:
	return randf() < prob

func format_money(amount: float) -> String:
	var neg = amount < 0
	var abs_val = abs(amount)
	var str_val: String
	if abs_val >= 1_000_000:
		str_val = "$%.2fM" % (abs_val / 1_000_000.0)
	elif abs_val >= 10_000:
		str_val = "$%.1fk" % (abs_val / 1000.0)
	else:
		str_val = "$%d" % int(abs_val)
	return ("-" + str_val) if neg else str_val
