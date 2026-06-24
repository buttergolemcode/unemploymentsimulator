# EventData.gd — Random events with branching choices
class_name EventData
extends RefCounted

static func get_random_event(gm: Node) -> Dictionary:
	var pool = _build_pool(gm)
	if pool.is_empty():
		return {}
	return pool[randi() % pool.size()]

static func _build_pool(gm: Node) -> Array:
	var pool: Array = []
	
	# Heat-driven events
	if gm.heat >= 60:
		pool.append({
			"title": "Police Raid",
			"description": "Two unmarked SUVs pulled up outside your apartment at 6 AM. They've got a warrant.",
			"choices": [
				{
					"label": "Bolt out the back window",
					"apply": func(g):
						return {
							"heat_delta": -10, "money_delta": -g.rand_int(500, 2000),
							"log_entries": [{"text": "You shimmied down the fire escape. Lost the stash but stayed free. Heat -10.", "type": "event"}],
						},
				},
				{
					"label": "Flush everything and play dumb",
					"apply": func(g):
						return {
							"heat_delta": -20, "money_delta": -g.rand_int(300, 1200),
							"log_entries": [{"text": "You flushed the product. Cops found nothing. Heat -20.", "type": "event"}],
						},
				},
				{
					"label": "Lawyer up ($5,000)",
					"apply": func(g):
						if g.money >= 5000:
							return {
								"money_delta": -5000, "heat_delta": -35,
								"log_entries": [{"text": "$5000 to a slick defense attorney. Charges dropped on a technicality. Heat -35.", "type": "event"}],
							}
						return {
							"heat_delta": -5,
							"log_entries": [{"text": "Couldn't afford the retainer. Public defender got you ROR but the heat is still on.", "type": "danger"}],
						},
				},
			],
		})
	
	if gm.heat >= 35 and gm.heat < 60:
		pool.append({
			"title": "A Witness Speaks Up",
			"description": "A bystander from your last scheme went to the cops.",
			"choices": [
				{
					"label": "Lawyer up ($1,500)",
					"apply": func(g):
						if g.money >= 1500:
							return {
								"money_delta": -1500, "heat_delta": -12,
								"log_entries": [{"text": "Attorney got the interview cancelled. Heat -12.", "type": "event"}],
							}
						return {
							"heat_delta": 8,
							"log_entries": [{"text": "Couldn't afford counsel. You stammered through the interview. Heat +8.", "type": "danger"}],
						},
				},
				{
					"label": "Lay low for the day",
					"apply": func(g):
						return {
							"heat_delta": -8,
							"log_entries": [{"text": "You went dark. Cops moved on. Heat -8.", "type": "event"}],
						},
				},
			],
		})
	
	# McDonald's bailouts (when broke)
	if gm.money < 100:
		pool.append({
			"title": "McDonald's Is Hiring",
			"description": "Your landlord is threatening eviction. There's a 'NOW HIRING' sign at McDonald's.",
			"choices": [
				{
					"label": "Take the job. Game over.",
					"apply": func(g):
						return {
							"phase": "lost", "lose_reason": "mcdonalds",
							"log_entries": [{"text": "You put on the uniform. You smell like fries forever.", "type": "danger"}],
						},
				},
				{
					"label": "Decline. Hustle harder.",
					"apply": func(g):
						return {
							"money_delta": 50, "rep_delta": 2,
							"log_entries": [{"text": "You told the manager you'd think about it. Found $50 in a coat pocket.", "type": "event"}],
						},
				},
			],
		})
	
	# Lucky breaks
	pool.append({
		"title": "Hot Tip from r/WallStreetBets",
		"description": "A mod just dropped 'DD' on a small-cap biotech. FDA approval news leaks tomorrow, allegedly.",
		"choices": [
			{
				"label": "Ape in $2,000",
				"apply": func(g):
					var stake = min(g.money, 2000)
					if stake < 200:
						return {"log_entries": [{"text": "Not enough to ape in. Missed the pump.", "type": "info"}]}
					if g.chance(0.55):
						var win = int(stake * (1.5 + randf() * 2))
						return {"money_delta": win, "log_entries": [{"text": "The DD was real! +$%d." % win, "type": "money"}]}
					return {"money_delta": -stake, "log_entries": [{"text": "The 'DD' was hopium. Stock dumped -40%% premarket. Lost $%d." % stake, "type": "danger"}]},
			},
			{
				"label": "Skip — sounds like a trap",
				"apply": func(g):
					return {"log_entries": [{"text": "You watched from the sidelines. The stock pumped. Then dumped.", "type": "info"}]},
			},
		],
	})
	
	pool.append({
		"title": "Uncle Louie Visits",
		"description": "Your shady uncle Louie is in town. He slides you an envelope with a wink.",
		"choices": [
			{
				"label": "Take the envelope",
				"apply": func(g):
					var amt = g.rand_int(300, 1200)
					return {"money_delta": amt, "heat_delta": 2, "log_entries": [{"text": "Uncle Louie slipped you $%d." % amt, "type": "money"}]},
			},
			{
				"label": "Politely refuse",
				"apply": func(g):
					return {"rep_delta": 1, "log_entries": [{"text": "You told Uncle Louie you're making your own way.", "type": "info"}]},
			},
		],
	})
	
	# Crew offers
	if gm.reputation >= 30:
		pool.append({
			"title": "A Crew Wants to Hire You",
			"description": "A local crew is offering 20% of all product moved in exchange for running their supply chain.",
			"choices": [
				{
					"label": "Join the crew",
					"apply": func(g):
						return {"money_delta": g.rand_int(2000, 5000), "heat_delta": 10, "rep_delta": 10,
							"log_entries": [{"text": "You shook on it. Signing bonus cleared.", "type": "money"}]},
				},
				{
					"label": "Stay solo",
					"apply": func(g):
						return {"rep_delta": 3, "log_entries": [{"text": "You told them you fly alone.", "type": "info"}]},
				},
			],
		})
	
	# Mom needs money
	pool.append({
		"title": "Mom Needs $500",
		"description": "Mom called. Her car broke down. She's crying.",
		"choices": [
			{
				"label": "Send the $500",
				"apply": func(g):
					if g.money >= 500:
						return {"money_delta": -500, "heat_delta": -3,
							"log_entries": [{"text": "You sent the money. Mom said she's proud of you. Heat -3.", "type": "event"}]}
					return {"rep_delta": -2, "log_entries": [{"text": "You had to tell her you couldn't. She hung up.", "type": "danger"}]},
			},
			{
				"label": "Pretend you didn't see the call",
				"apply": func(g):
					return {"rep_delta": -1, "log_entries": [{"text": "You let it go to voicemail. Again.", "type": "info"}]},
			},
		],
	})
	
	# Mugging
	pool.append({
		"title": "You Got Mugged",
		"description": "Walking home from a deal, two guys jumped you in an alley.",
		"choices": [
			{
				"label": "Take the loss",
				"apply": func(g):
					var lost = min(g.money, g.rand_int(200, 800))
					return {"money_delta": -lost, "log_entries": [{"text": "They took $%d and your cracked iPhone 11." % lost, "type": "danger"}]},
			},
			{
				"label": "Fight back",
				"apply": func(g):
					if g.chance(0.35 + g.skills.robbery * 0.04):
						var kept = g.rand_int(500, 1500)
						return {"money_delta": kept, "heat_delta": 4, "rep_delta": 3,
							"log_entries": [{"text": "You dropped the bigger one with a liver shot. They ran. You picked up $%d they dropped." % kept, "type": "money"}]}
					var lost = min(g.money, g.rand_int(400, 1500))
					return {"money_delta": -lost, "heat_delta": 8,
						"log_entries": [{"text": "They beat the brakes off you. Lost $%d." % lost, "type": "danger"}]},
			},
		],
	})
	
	return pool
