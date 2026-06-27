# EventData.gd — Random events with branching choices (no lambdas)
class_name EventData
extends RefCounted

static func get_random_event(gm: Node) -> Dictionary:
	var pool: Array = _build_pool(gm)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]

static func _build_pool(gm: Node) -> Array:
	var pool: Array = []
	
	if gm.heat >= 60:
		pool.append({
			"title": "Police Raid",
			"description": "Two unmarked SUVs pulled up outside your apartment at 6 AM.",
			"choices": [
				{"label": "Bolt out the back window"},
				{"label": "Flush everything and play dumb"},
				{"label": "Lawyer up ($5,000)"},
			],
			"event_type": "raid",
		})
	
	if gm.heat >= 35 and gm.heat < 60:
		pool.append({
			"title": "A Witness Speaks Up",
			"description": "A bystander from your last scheme went to the cops.",
			"choices": [
				{"label": "Lawyer up ($1,500)"},
				{"label": "Lay low for the day"},
			],
			"event_type": "witness",
		})
	
	if gm.money < 100:
		pool.append({
			"title": "McDonald's Is Hiring",
			"description": "There's a 'NOW HIRING' sign at McDonald's.",
			"choices": [
				{"label": "Take the job. Game over."},
				{"label": "Decline. Hustle harder."},
			],
			"event_type": "mcdonalds",
		})
	
	pool.append({
		"title": "Hot Tip from r/WallStreetBets",
		"description": "A mod just dropped 'DD' on a small-cap biotech.",
		"choices": [
			{"label": "Ape in $2,000"},
			{"label": "Skip — sounds like a trap"},
		],
		"event_type": "hot_tip",
	})
	
	pool.append({
		"title": "Uncle Louie Visits",
		"description": "Your shady uncle Louie slides you an envelope with a wink.",
		"choices": [
			{"label": "Take the envelope"},
			{"label": "Politely refuse"},
		],
		"event_type": "uncle",
	})
	
	if gm.reputation >= 30:
		pool.append({
			"title": "A Crew Wants to Hire You",
			"description": "A local crew is offering 20% of all product moved.",
			"choices": [
				{"label": "Join the crew"},
				{"label": "Stay solo"},
			],
			"event_type": "crew",
		})
	
	pool.append({
		"title": "Mom Needs $500",
		"description": "Mom called. Her car broke down. She's crying.",
		"choices": [
			{"label": "Send the $500"},
			{"label": "Pretend you didn't see the call"},
		],
		"event_type": "mom",
	})
	
	pool.append({
		"title": "You Got Mugged",
		"description": "Two guys jumped you in an alley.",
		"choices": [
			{"label": "Take the loss"},
			{"label": "Fight back"},
		],
		"event_type": "mugging",
	})
	
	return pool

static func apply_choice(gm: Node, event: Dictionary, choice_index: int) -> Dictionary:
	var event_type: String = event.get("event_type", "")
	
	match event_type:
		"raid":
			return _resolve_raid(gm, choice_index)
		"witness":
			return _resolve_witness(gm, choice_index)
		"mcdonalds":
			return _resolve_mcdonalds(gm, choice_index)
		"hot_tip":
			return _resolve_hot_tip(gm, choice_index)
		"uncle":
			return _resolve_uncle(gm, choice_index)
		"crew":
			return _resolve_crew(gm, choice_index)
		"mom":
			return _resolve_mom(gm, choice_index)
		"mugging":
			return _resolve_mugging(gm, choice_index)
		_:
			return {}

static func _resolve_raid(gm: Node, choice: int) -> Dictionary:
	match choice:
		0: return {"heat_delta": -10.0, "money_delta": -gm.rand_int(500, 2000),
			"log_entries": [{"text": "You shimmied down the fire escape. Lost the stash. Heat -10.", "type": "event"}]}
		1: return {"heat_delta": -20.0, "money_delta": -gm.rand_int(300, 1200),
			"log_entries": [{"text": "You flushed the product. Cops found nothing. Heat -20.", "type": "event"}]}
		2:
			if gm.money >= 5000:
				return {"money_delta": -5000.0, "heat_delta": -35.0,
					"log_entries": [{"text": "$5000 to a slick defense attorney. Charges dropped. Heat -35.", "type": "event"}]}
			return {"heat_delta": -5.0,
				"log_entries": [{"text": "Couldn't afford the retainer. Heat -5.", "type": "danger"}]}
		_: return {}

static func _resolve_witness(gm: Node, choice: int) -> Dictionary:
	match choice:
		0:
			if gm.money >= 1500:
				return {"money_delta": -1500.0, "heat_delta": -12.0,
					"log_entries": [{"text": "Attorney got the interview cancelled. Heat -12.", "type": "event"}]}
			return {"heat_delta": 8.0,
				"log_entries": [{"text": "Couldn't afford counsel. Heat +8.", "type": "danger"}]}
		1: return {"heat_delta": -8.0,
			"log_entries": [{"text": "You went dark. Cops moved on. Heat -8.", "type": "event"}]}
		_: return {}

static func _resolve_mcdonalds(gm: Node, choice: int) -> Dictionary:
	match choice:
		0: return {"phase": "lost", "lose_reason": "mcdonalds",
			"log_entries": [{"text": "You put on the uniform. The dream is dead.", "type": "danger"}]}
		1: return {"money_delta": 50.0, "rep_delta": 2.0,
			"log_entries": [{"text": "Found $50 in a coat pocket. The dream survives.", "type": "event"}]}
		_: return {}

static func _resolve_hot_tip(gm: Node, choice: int) -> Dictionary:
	match choice:
		0:
			var stake = min(gm.money, 2000)
			if stake < 200:
				return {"log_entries": [{"text": "Not enough to ape in. Missed the pump.", "type": "info"}]}
			if gm.chance(0.55):
				var win = int(stake * (1.5 + randf() * 2))
				return {"money_delta": float(win),
					"log_entries": [{"text": "The DD was real! +$%d." % win, "type": "money"}]}
			return {"money_delta": -stake,
				"log_entries": [{"text": "The 'DD' was hopium. Lost $%d." % int(stake), "type": "danger"}]}
		1: return {"log_entries": [{"text": "You watched from the sidelines.", "type": "info"}]}
		_: return {}

static func _resolve_uncle(gm: Node, choice: int) -> Dictionary:
	match choice:
		0:
			var amt = gm.rand_int(300, 1200)
			return {"money_delta": float(amt), "heat_delta": 2.0,
				"log_entries": [{"text": "Uncle Louie slipped you $%d." % amt, "type": "money"}]}
		1: return {"rep_delta": 1.0,
			"log_entries": [{"text": "You told Uncle Louie you're making your own way.", "type": "info"}]}
		_: return {}

static func _resolve_crew(gm: Node, choice: int) -> Dictionary:
	match choice:
		0: return {"money_delta": float(gm.rand_int(2000, 5000)), "heat_delta": 10.0, "rep_delta": 10.0,
			"log_entries": [{"text": "You shook on it. Signing bonus cleared.", "type": "money"}]}
		1: return {"rep_delta": 3.0,
			"log_entries": [{"text": "You told them you fly alone.", "type": "info"}]}
		_: return {}

static func _resolve_mom(gm: Node, choice: int) -> Dictionary:
	match choice:
		0:
			if gm.money >= 500:
				return {"money_delta": -500.0, "heat_delta": -3.0,
					"log_entries": [{"text": "You sent the money. Mom said she's proud. Heat -3.", "type": "event"}]}
			return {"rep_delta": -2.0,
				"log_entries": [{"text": "You had to tell her you couldn't.", "type": "danger"}]}
		1: return {"rep_delta": -1.0,
			"log_entries": [{"text": "You let it go to voicemail. Again.", "type": "info"}]}
		_: return {}

static func _resolve_mugging(gm: Node, choice: int) -> Dictionary:
	match choice:
		0:
			var lost = min(gm.money, gm.rand_int(200, 800))
			return {"money_delta": -lost,
				"log_entries": [{"text": "They took $%d and your cracked iPhone." % int(lost), "type": "danger"}]}
		1:
			if gm.chance(0.35 + gm.skills.robbery * 0.04):
				var kept = gm.rand_int(500, 1500)
				return {"money_delta": float(kept), "heat_delta": 4.0, "rep_delta": 3.0,
					"log_entries": [{"text": "You dropped the bigger one. They ran. +$%d." % kept, "type": "money"}]}
			var lost = min(gm.money, gm.rand_int(400, 1500))
			return {"money_delta": -lost, "heat_delta": 8.0,
				"log_entries": [{"text": "They beat the brakes off you. Lost $%d." % int(lost), "type": "danger"}]}
		_: return {}
