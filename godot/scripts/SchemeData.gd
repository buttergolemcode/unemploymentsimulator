# SchemeData.gd — All 8 schemes with their actions (no lambdas)
class_name SchemeData
extends RefCounted

static func get_all_schemes() -> Array:
	return [
		{"id": "ecom", "name": "E-Com", "emoji": "📦", "description": "Flip thrift finds, dropship garbage, run review farms.", "heat_risk": "low", "reward_range": "$40 - $2,500"},
		{"id": "trading", "name": "Day Trading", "emoji": "📈", "description": "Yolo your savings on meme stocks and 0DTE options.", "heat_risk": "low", "reward_range": "$50 - $15,000"},
		{"id": "gambling", "name": "Gambling", "emoji": "🎰", "description": "Slots, roulette, blackjack with card counting.", "heat_risk": "low", "reward_range": "-$500 to +$50,000"},
		{"id": "drugs", "name": "Selling Drugs", "emoji": "💊", "description": "Slang weed, flip pills, run supply from the plug.", "heat_risk": "high", "reward_range": "$40 - $4,000"},
		{"id": "scam", "name": "Scamming", "emoji": "🎣", "description": "Phishing, romance scams, pig-butchering.", "heat_risk": "medium", "reward_range": "$80 - $8,000"},
		{"id": "robbery", "name": "Robbing", "emoji": "🔫", "description": "Snatch phones, burgle houses, arm-rob corner stores.", "heat_risk": "extreme", "reward_range": "$100 - $14,000"},
		{"id": "taxfraud", "name": "Tax Fraud", "emoji": "🧾", "description": "Fabricate dependents, fake business losses.", "heat_risk": "medium", "reward_range": "$1,000 - $3,500 / filing"},
		{"id": "wirefraud", "name": "Wire Fraud", "emoji": "💸", "description": "Fake vendor invoices, CEO impersonation wires.", "heat_risk": "high", "reward_range": "$8,000 - $130,000"},
	]

static func get_scheme(scheme_id: String) -> Dictionary:
	for s in get_all_schemes():
		if s.id == scheme_id:
			return s
	return {}

static func get_actions(scheme_id: String) -> Array:
	var actions: Array = []
	match scheme_id:
		"ecom":
			actions = [
				{"id": "flip_finds", "label": "Flip Thrift Finds", "description": "Hit up local Goodwills, list finds on eBay.", "cost": 1},
				{"id": "dropship_batch", "label": "Run Dropship Batch", "description": "Order cheap gadgets from AliExpress, mark up 4x.", "cost": 2},
				{"id": "review_farm", "label": "Run Review Farm", "description": "Pay offshore workers $1 each for 5-star reviews.", "cost": 2},
			]
		"trading":
			actions = [
				{"id": "daytrade_meme", "label": "Yolo on Meme Stock", "description": "Put it all on $PEPE or $ROPE.", "cost": 1},
				{"id": "options_play", "label": "0DTE Options Gamble", "description": "Buy same-day-expiry call options.", "cost": 1},
				{"id": "pump_dump", "label": "Pump & Dump Microcap", "description": "Buy illiquid penny stock, hype it in Discord.", "cost": 2},
			]
		"gambling":
			actions = [
				{"id": "slots", "label": "Slot Machine", "description": "Pull the lever. Mostly lose, sometimes win.", "cost": 1},
				{"id": "roulette_red", "label": "Roulette — Bet Red", "description": "Bet $500 on red. Pays 1:1. 48.6% to win.", "cost": 1},
				{"id": "blackjack_count", "label": "Count Cards at Blackjack", "description": "$100-min table. If pit boss notices...", "cost": 2},
			]
		"drugs":
			actions = [
				{"id": "slang_bud", "label": "Slang a Bag of Bud", "description": "Low-stakes weed deals.", "cost": 1},
				{"id": "flip_pills", "label": "Flip a Bottle of Pills", "description": "Move prescription painkillers.", "cost": 1},
				{"id": "supply_run", "label": "Pick Up from the Plug", "description": "Drive 2 hours to the wholesale plug.", "cost": 2},
			]
		"scam":
			actions = [
				{"id": "phish_emails", "label": "Send Phishing Emails", "description": "Blast 10k fake 'Netflix' emails.", "cost": 1},
				{"id": "romance_scam", "label": "Run a Romance Scam", "description": "Catfish a lonely boomer for 2 weeks.", "cost": 2},
				{"id": "pig_butchering", "label": "Pig-Butchering Scheme", "description": "Weeks of 'crypto investment' grooming.", "cost": 2},
			]
		"robbery":
			actions = [
				{"id": "snatch_phone", "label": "Snatch a Phone", "description": "Grab a tourist's iPhone off a cafe table.", "cost": 1},
				{"id": "burglary", "label": "Burglarize a House", "description": "Suburban home, owner on vacation.", "cost": 2},
				{"id": "armed_robbery", "label": "Arm-Rob a Corner Store", "description": "Mask up, walk in with a replica Glock.", "cost": 3},
			]
		"taxfraud":
			actions = [
				{"id": "setup_tax_fraud", "label": "Set Up Fake Tax Return Scheme", "description": "Fabricate 12 dependents and $80k expenses.", "cost": 3},
				{"id": "harvest_refund", "label": "Harvest Tax Refund", "description": "File another batch of fraudulent returns.", "cost": 1},
			]
		"wirefraud":
			actions = [
				{"id": "fake_invoice", "label": "Send Fake Vendor Invoice", "description": "Spoof a vendor's email, send $15k invoice.", "cost": 2},
				{"id": "ceo_fraud", "label": "CEO Impersonation Wire", "description": "Pressure CFO into wiring $50-150k.", "cost": 3},
			]
	return actions

static func get_action(scheme_id: String, action_id: String) -> Dictionary:
	for a in get_actions(scheme_id):
		if a.id == action_id:
			return a
	return {}

static func is_action_available(gm: Node, scheme_id: String, action_id: String) -> bool:
	if scheme_id == "taxfraud" and action_id == "setup_tax_fraud":
		return not gm.tax_setup
	if scheme_id == "taxfraud" and action_id == "harvest_refund":
		return gm.tax_setup
	return true

static func perform_action(gm: Node, scheme_id: String, action_id: String) -> Dictionary:
	var action = get_action(scheme_id, action_id)
	if action.is_empty():
		return {"success": false, "message": "Unknown action"}
	
	if not is_action_available(gm, scheme_id, action_id):
		return {"success": false, "message": "Not available"}
	
	if gm.actions_left < action.get("cost", 1):
		return {"success": false, "message": "Not enough actions"}
	
	# Dispatch to the correct handler
	var result: Dictionary
	match scheme_id + "_" + action_id:
		"ecom_flip_finds": result = _ecom_flip_finds(gm)
		"ecom_dropship_batch": result = _ecom_dropship(gm)
		"ecom_review_farm": result = _ecom_review_farm(gm)
		"trading_daytrade_meme": result = _trading_meme(gm)
		"trading_options_play": result = _trading_options(gm)
		"trading_pump_dump": result = _trading_pump_dump(gm)
		"gambling_slots": result = _gambling_slots(gm)
		"gambling_roulette_red": result = _gambling_roulette(gm)
		"gambling_blackjack_count": result = _gambling_blackjack(gm)
		"drugs_slang_bud": result = _drugs_slang(gm)
		"drugs_flip_pills": result = _drugs_pills(gm)
		"drugs_supply_run": result = _drugs_supply(gm)
		"scam_phish_emails": result = _scam_phish(gm)
		"scam_romance_scam": result = _scam_romance(gm)
		"scam_pig_butchering": result = _scam_pig(gm)
		"robbery_snatch_phone": result = _robbery_snatch(gm)
		"robbery_burglary": result = _robbery_burglary(gm)
		"robbery_armed_robbery": result = _robbery_armed(gm)
		"taxfraud_setup_tax_fraud": result = _taxfraud_setup(gm)
		"taxfraud_harvest_refund": result = _taxfraud_harvest(gm)
		"wirefraud_fake_invoice": result = _wirefraud_invoice(gm)
		"wirefraud_ceo_fraud": result = _wirefraud_ceo(gm)
		_: return {"success": false, "message": "Unknown action"}
	
	result["cost"] = action.get("cost", 1)
	result["success"] = true
	return result

# ============================================================
# E-COM actions
# ============================================================
static func _ecom_flip_finds(gm) -> Dictionary:
	var skill = gm.skills.ecom
	var profit = gm.rand_int(40, 180) * skill
	if gm.chance(0.05):
		return {"money_delta": -gm.rand_int(20, 80), "heat_delta": 1.0, "xp_gain": 8,
			"log_text": "Bought a 'vintage' vase that was a reproduction. Lost cash.", "log_type": "danger"}
	return {"money_delta": float(profit), "xp_gain": 10,
		"log_text": "Flipped a thrift-store jacket for $%d." % profit, "log_type": "money"}

static func _ecom_dropship(gm) -> Dictionary:
	var skill = gm.skills.ecom
	var base = gm.rand_int(120, 400) * skill
	if gm.chance(0.12):
		return {"money_delta": -gm.rand_int(80, 200), "heat_delta": 2.0, "xp_gain": 12,
			"log_text": "Wave of chargebacks. PayPal froze funds.", "log_type": "danger"}
	return {"money_delta": float(base), "xp_gain": 15,
		"log_text": "Sold 12 units of 'ergonomic toe-stretchers' at 4x markup. Net: $%d." % base, "log_type": "money"}

static func _ecom_review_farm(gm) -> Dictionary:
	var skill = gm.skills.ecom
	var profit = gm.rand_int(150, 500) * skill
	if gm.chance(0.18):
		return {"money_delta": -gm.rand_int(50, 150), "heat_delta": 8.0, "xp_gain": 6,
			"log_text": "Amazon flagged your listing for 'suspicious review activity.'", "log_type": "danger"}
	return {"money_delta": float(profit), "heat_delta": 2.0, "xp_gain": 12,
		"log_text": "Reviews boosted conversion rate. Cleared $%d." % profit, "log_type": "money"}

# ============================================================
# Trading actions
# ============================================================
static func _trading_meme(gm) -> Dictionary:
	var skill = gm.skills.trading
	var roll = randf()
	if roll < 0.4:
		return {"money_delta": -gm.rand_int(80, 300), "xp_gain": 12,
			"log_text": "Meme stock cratered. You sold at the bottom.", "log_type": "danger"}
	elif roll < 0.7:
		var p = gm.rand_int(50, 200) * skill
		return {"money_delta": float(p), "xp_gain": 12, "log_text": "Caught a pump. +$%d." % p, "log_type": "money"}
	elif roll < 0.92:
		var p = gm.rand_int(150, 600) * skill
		return {"money_delta": float(p), "xp_gain": 15, "log_text": "Earnings beat. +$%d." % p, "log_type": "money"}
	else:
		var p = gm.rand_int(800, 2500) * skill
		return {"money_delta": float(p), "xp_gain": 20, "log_text": "3x runner! +$%d tendies." % p, "log_type": "money"}

static func _trading_options(gm) -> Dictionary:
	var skill = gm.skills.trading
	var stake = min(gm.money, 200 + skill * 50)
	if gm.chance(0.32 + skill * 0.015):
		var profit = int(stake * (1.5 + randf() * 4))
		return {"money_delta": float(profit), "xp_gain": 15, "log_text": "0DTE printed. +$%d." % profit, "log_type": "money"}
	return {"money_delta": -stake, "xp_gain": 8, "log_text": "0DTE went to zero. -$%d." % int(stake), "log_type": "danger"}

static func _trading_pump_dump(gm) -> Dictionary:
	var skill = gm.skills.trading
	var profit = gm.rand_int(400, 1500) * skill
	if gm.chance(0.22):
		return {"money_delta": -gm.rand_int(200, 800), "heat_delta": 15.0, "xp_gain": 5,
			"log_text": "SEC opened an inquiry.", "log_type": "danger"}
	return {"money_delta": float(profit), "heat_delta": 4.0, "xp_gain": 18,
		"log_text": "Hyped $ZZZZ on Discord. +$%d." % profit, "log_type": "money"}

# ============================================================
# Gambling actions
# ============================================================
static func _gambling_slots(gm) -> Dictionary:
	var roll = randf()
	if roll < 0.6:
		return {"money_delta": -50.0, "xp_gain": 4, "log_text": "Slots ate your $50.", "log_type": "danger"}
	elif roll < 0.9:
		var w = gm.rand_int(80, 250)
		return {"money_delta": float(w), "xp_gain": 6, "log_text": "Three cherries! +$%d." % w, "log_type": "money"}
	elif roll < 0.99:
		var w = gm.rand_int(800, 2500)
		return {"money_delta": float(w), "xp_gain": 10, "log_text": "MINOR JACKPOT! +$%d." % w, "log_type": "money"}
	else:
		var w = gm.rand_int(15000, 50000)
		return {"money_delta": float(w), "xp_gain": 20, "log_text": "MEGA JACKPOT! +$%d!" % w, "log_type": "money"}

static func _gambling_roulette(gm) -> Dictionary:
	var stake = min(gm.money, 500)
	var spin = gm.rand_int(0, 36)
	var is_red = spin != 0 and [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36].has(spin)
	if is_red:
		return {"money_delta": stake, "xp_gain": 6, "log_text": "Spin landed %d (RED). +$%d." % [spin, int(stake)], "log_type": "money"}
	return {"money_delta": -stake, "xp_gain": 4, "log_text": "Spin landed %d. Lost $%d." % [spin, int(stake)], "log_type": "danger"}

static func _gambling_blackjack(gm) -> Dictionary:
	var skill = gm.skills.gambling
	if gm.chance(0.18):
		return {"money_delta": -gm.rand_int(200, 600), "heat_delta": 6.0, "xp_gain": 5,
			"log_text": "Pit boss tapped your shoulder.", "log_type": "danger"}
	if gm.chance(0.5 + skill * 0.025):
		var p = gm.rand_int(200, 800) * skill
		return {"money_delta": float(p), "xp_gain": 12, "log_text": "Counting paid off. +$%d." % p, "log_type": "money"}
	return {"money_delta": -gm.rand_int(150, 500), "xp_gain": 8, "log_text": "Bad shoe. -$%d." % gm.rand_int(150, 500), "log_type": "danger"}

# ============================================================
# Drugs actions
# ============================================================
static func _drugs_slang(gm) -> Dictionary:
	var skill = gm.skills.drugs
	var profit = gm.rand_int(40, 90) * skill
	if gm.chance(0.07):
		return {"money_delta": 0.0, "heat_delta": 6.0, "rep_delta": -2.0, "xp_gain": 4,
			"log_text": "Buyer ghosted. Might've been a CI.", "log_type": "heat"}
	return {"money_delta": float(profit), "heat_delta": 2.0, "rep_delta": 1.0, "xp_gain": 10,
		"log_text": "Sold an eighth to a regular for $%d." % profit, "log_type": "money"}

static func _drugs_pills(gm) -> Dictionary:
	var skill = gm.skills.drugs
	var profit = gm.rand_int(300, 800) * skill
	if gm.chance(0.14):
		return {"money_delta": -gm.rand_int(100, 400), "heat_delta": 14.0, "xp_gain": 6,
			"log_text": "Buyer was wearing a wire. You bolted but lost the product.", "log_type": "danger"}
	return {"money_delta": float(profit), "heat_delta": 6.0, "rep_delta": 2.0, "xp_gain": 12,
		"log_text": "Moved a bottle of blues for $%d." % profit, "log_type": "money"}

static func _drugs_supply(gm) -> Dictionary:
	var skill = gm.skills.drugs
	var profit = gm.rand_int(1500, 4000) * skill
	if gm.chance(0.20):
		var bribe = gm.rand_int(300, 800)
		if gm.money > bribe + 200 and gm.chance(0.7):
			return {"money_delta": -bribe, "heat_delta": 8.0, "xp_gain": 8,
				"log_text": "Highway patrol pulled you over. Slipped the officer $%d." % bribe, "log_type": "heat"}
		return {"money_delta": -gm.rand_int(500, 1500), "heat_delta": 30.0, "xp_gain": 4,
			"log_text": "Got pulled over with product in the trunk.", "log_type": "danger"}
	return {"money_delta": float(profit), "heat_delta": 8.0, "rep_delta": 5.0, "xp_gain": 20,
		"log_text": "Plug hooked you up. Flipped the whole zip for +$%d." % profit, "log_type": "money"}

# ============================================================
# Scam actions
# ============================================================
static func _scam_phish(gm) -> Dictionary:
	var skill = gm.skills.scam
	if gm.chance(0.10):
		return {"money_delta": 0.0, "heat_delta": 5.0, "xp_gain": 5, "log_text": "Email provider flagged the domain.", "log_type": "heat"}
	var profit = gm.rand_int(80, 250) * skill
	return {"money_delta": float(profit), "heat_delta": 2.0, "xp_gain": 10,
		"log_text": "Got %d victims. Net: +$%d." % [gm.rand_int(3, 9), profit], "log_type": "money"}

static func _scam_romance(gm) -> Dictionary:
	var skill = gm.skills.scam
	if gm.chance(0.18):
		return {"money_delta": 0.0, "heat_delta": 8.0, "rep_delta": -1.0, "xp_gain": 4,
			"log_text": "Target's grandkid reverse-image-searched your pics.", "log_type": "heat"}
	var profit = gm.rand_int(300, 1200) * skill
	return {"money_delta": float(profit), "heat_delta": 4.0, "xp_gain": 14,
		"log_text": "'Margaret' sent $%d in Apple gift cards." % profit, "log_type": "money"}

static func _scam_pig(gm) -> Dictionary:
	var skill = gm.skills.scam
	if gm.chance(0.28):
		return {"money_delta": -gm.rand_int(100, 500), "heat_delta": 18.0, "xp_gain": 6,
			"log_text": "Target reported to FBI IC3.", "log_type": "danger"}
	var profit = gm.rand_int(2500, 8000) * skill
	return {"money_delta": float(profit), "heat_delta": 8.0, "rep_delta": 3.0, "xp_gain": 22,
		"log_text": "'Daniel' withdrew his 'crypto gains'. +$%d." % profit, "log_type": "money"}

# ============================================================
# Robbery actions
# ============================================================
static func _robbery_snatch(gm) -> Dictionary:
	var skill = gm.skills.robbery
	if gm.chance(0.15):
		return {"money_delta": 0.0, "heat_delta": 12.0, "xp_gain": 4,
			"log_text": "Tourist chased you down. CCTV has your face.", "log_type": "danger"}
	var profit = gm.rand_int(100, 350) * skill
	return {"money_delta": float(profit), "heat_delta": 4.0, "rep_delta": 1.0, "xp_gain": 10,
		"log_text": "Snatched an iPhone 15 Pro, fenced for $%d." % profit, "log_type": "money"}

static func _robbery_burglary(gm) -> Dictionary:
	var skill = gm.skills.robbery
	if gm.chance(0.22):
		return {"money_delta": -gm.rand_int(100, 300), "heat_delta": 25.0, "xp_gain": 6,
			"log_text": "Neighbor's Ring camera caught your face.", "log_type": "danger"}
	var profit = gm.rand_int(1500, 5000) * skill
	return {"money_delta": float(profit), "heat_delta": 10.0, "rep_delta": 4.0, "xp_gain": 18,
		"log_text": "Jewelry, electronics, cash. Fenced for +$%d." % profit, "log_type": "money"}

static func _robbery_armed(gm) -> Dictionary:
	var skill = gm.skills.robbery
	if gm.chance(0.35):
		return {"money_delta": 0.0, "heat_delta": 50.0, "xp_gain": 4,
			"log_text": "Clerk hit the silent alarm. Cops got your plates.", "log_type": "danger"}
	var profit = gm.rand_int(4000, 14000) * skill
	return {"money_delta": float(profit), "heat_delta": 18.0, "rep_delta": 8.0, "xp_gain": 25,
		"log_text": "Walked out with $%d in small bills." % profit, "log_type": "money"}

# ============================================================
# Tax Fraud actions
# ============================================================
static func _taxfraud_setup(gm) -> Dictionary:
	gm.tax_setup = true
	return {"money_delta": -300.0, "heat_delta": 4.0, "xp_gain": 15, "tax_setup": true,
		"log_text": "Hired a 'creative accountant' off Craigslist. $300 fee.", "log_type": "info"}

static func _taxfraud_harvest(gm) -> Dictionary:
	var skill = gm.skills.taxfraud
	if gm.chance(0.10):
		return {"money_delta": -gm.rand_int(500, 2000), "heat_delta": 20.0, "xp_gain": 6,
			"log_text": "IRS flagged your batch for audit.", "log_type": "danger"}
	var profit = gm.rand_int(1000, 3500) * skill
	return {"money_delta": float(profit), "heat_delta": 3.0, "xp_gain": 12,
		"log_text": "Filed 4 fake returns. Treasury deposited $%d." % profit, "log_type": "money"}

# ============================================================
# Wire Fraud actions
# ============================================================
static func _wirefraud_invoice(gm) -> Dictionary:
	var skill = gm.skills.wirefraud
	if gm.chance(0.22):
		return {"money_delta": 0.0, "heat_delta": 15.0, "xp_gain": 5,
			"log_text": "AP clerk called the real vendor. FBI has your wire info.", "log_type": "danger"}
	var profit = gm.rand_int(8000, 22000) * skill
	return {"money_delta": float(profit), "heat_delta": 6.0, "rep_delta": 3.0, "xp_gain": 20,
		"log_text": "AP paid the fake invoice. +$%d hit your mule account." % profit, "log_type": "money"}

static func _wirefraud_ceo(gm) -> Dictionary:
	var skill = gm.skills.wirefraud
	if gm.chance(0.38):
		return {"money_delta": 0.0, "heat_delta": 30.0, "xp_gain": 4,
			"log_text": "CFO smelled something off. Secret Service opened a file.", "log_type": "danger"}
	var profit = gm.rand_int(40000, 130000) * skill
	return {"money_delta": float(profit), "heat_delta": 12.0, "rep_delta": 6.0, "xp_gain": 30,
		"log_text": "CFO wired $%d for the 'urgent acquisition'." % profit, "log_type": "money"}
