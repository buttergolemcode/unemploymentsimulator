# SchemeData.gd — All 8 schemes with their actions
# Static data class — no instance needed
class_name SchemeData

extends RefCounted

# ============================================================
# Scheme definitions
# ============================================================
const SCHEMES: Array = [
	{
		"id": "ecom",
		"name": "E-Com",
		"emoji": "📦",
		"tagline": "Capitalism, but legal-ish",
		"description": "Flip thrift finds, dropship garbage, run review farms. Low heat, slow money.",
		"heat_risk": "low",
		"reward_range": "$40 - $2,500",
	},
	{
		"id": "trading",
		"name": "Day Trading",
		"emoji": "📈",
		"tagline": "Stock market casino",
		"description": "Yolo your savings on meme stocks, 0DTE options, pump-and-dumps. Zero heat but high variance.",
		"heat_risk": "low",
		"reward_range": "$50 - $15,000",
	},
	{
		"id": "gambling",
		"name": "Gambling",
		"emoji": "🎰",
		"tagline": "The original side hustle",
		"description": "Slots, roulette, blackjack with card counting. Legal but high variance.",
		"heat_risk": "low",
		"reward_range": "-$500 to +$50,000",
	},
	{
		"id": "drugs",
		"name": "Selling Drugs",
		"emoji": "💊",
		"tagline": "Old reliable",
		"description": "Slang weed, flip pills, run supply from the plug. Scales with reputation.",
		"heat_risk": "high",
		"reward_range": "$40 - $4,000",
	},
	{
		"id": "scam",
		"name": "Scamming",
		"emoji": "🎣",
		"tagline": "The internet is your mark",
		"description": "Phishing, romance scams, pig-butchering. FBI loves these.",
		"heat_risk": "medium",
		"reward_range": "$80 - $8,000",
	},
	{
		"id": "robbery",
		"name": "Robbing",
		"emoji": "🔫",
		"tagline": "High risk, high reward",
		"description": "Snatch phones, burgle houses, arm-rob corner stores. Highest payouts.",
		"heat_risk": "extreme",
		"reward_range": "$100 - $14,000",
	},
	{
		"id": "taxfraud",
		"name": "Tax Fraud",
		"emoji": "🧾",
		"tagline": "Sticking it to the IRS",
		"description": "Fabricate dependents, fake business losses. Setup fee, then passive income.",
		"heat_risk": "medium",
		"reward_range": "$1,000 - $3,500 / filing",
	},
	{
		"id": "wirefraud",
		"name": "Wire Fraud",
		"emoji": "💸",
		"tagline": "Corporate treasury, your treasury",
		"description": "Fake vendor invoices, CEO impersonation wires. Big money, big risk.",
		"heat_risk": "high",
		"reward_range": "$8,000 - $130,000",
	},
]

# ============================================================
# Actions per scheme
# ============================================================
static func get_scheme(scheme_id: String) -> Dictionary:
	for s in SCHEMES:
		if s.id == scheme_id:
			return s
	return {}

static func get_all_schemes() -> Array:
	return SCHEMES

static func get_actions(scheme_id: String) -> Array:
	match scheme_id:
		"ecom": return _ecom_actions()
		"trading": return _trading_actions()
		"gambling": return _gambling_actions()
		"drugs": return _drugs_actions()
		"scam": return _scam_actions()
		"robbery": return _robbery_actions()
		"taxfraud": return _taxfraud_actions()
		"wirefraud": return _wirefraud_actions()
		_: return []

static func get_action(scheme_id: String, action_id: String) -> Dictionary:
	for a in get_actions(scheme_id):
		if a.id == action_id:
			return a
	return {}

# ============================================================
# E-COM
# ============================================================
static func _ecom_actions() -> Array:
	return [
		{
			"id": "flip_finds",
			"label": "Flip Thrift Finds",
			"description": "Hit up local Goodwills, list finds on eBay.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.ecom
				var profit = gm.rand_int(40, 180) * skill
				if gm.chance(0.05):
					return {"money_delta": -gm.rand_int(20, 80), "heat_delta": 1, "xp_gain": 8,
						"log_text": "Bought a 'vintage' vase that was a reproduction. Lost cash.", "log_type": "danger"}
				return {"money_delta": profit, "xp_gain": 10,
					"log_text": "Flipped a thrift-store jacket for $%d." % profit, "log_type": "money"},
		},
		{
			"id": "dropship_batch",
			"label": "Run Dropship Batch",
			"description": "Order cheap gadgets from AliExpress, mark up 4x.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.ecom
				var base = gm.rand_int(120, 400) * skill
				if gm.chance(0.12):
					return {"money_delta": -gm.rand_int(80, 200), "heat_delta": 2, "xp_gain": 12,
						"log_text": "Wave of chargebacks hit your store — PayPal froze funds.", "log_type": "danger"}
				return {"money_delta": base, "xp_gain": 15,
					"log_text": "Sold 12 units of 'ergonomic toe-stretchers' at 4x markup. Net: $%d." % base, "log_type": "money"},
		},
		{
			"id": "review_farm",
			"label": "Run Review Farm",
			"description": "Pay offshore workers $1 each for 5-star reviews.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.ecom
				var profit = gm.rand_int(150, 500) * skill
				if gm.chance(0.18):
					return {"money_delta": -gm.rand_int(50, 150), "heat_delta": 8, "xp_gain": 6,
						"log_text": "Amazon flagged your listing for 'suspicious review activity.'", "log_type": "danger"}
				return {"money_delta": profit, "heat_delta": 2, "xp_gain": 12,
					"log_text": "Reviews boosted conversion rate. Cleared $%d this batch." % profit, "log_type": "money"},
		},
	]

# ============================================================
# TRADING
# ============================================================
static func _trading_actions() -> Array:
	return [
		{
			"id": "daytrade_meme",
			"label": "Yolo on Meme Stock",
			"description": "Put it all on $PEPE or $ROPE.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.trading
				var roll = randf()
				if roll < 0.4:
					var loss = -gm.rand_int(80, 300)
					return {"money_delta": loss, "xp_gain": 12,
						"log_text": "Meme stock cratered. Reddit says 'diamond hands.' You sold at the bottom.", "log_type": "danger"}
				elif roll < 0.7:
					var profit = gm.rand_int(50, 200) * skill
					return {"money_delta": profit, "xp_gain": 12,
						"log_text": "Caught a +%d%% pump. Out at +$%d." % [gm.rand_int(5, 20), profit], "log_type": "money"}
				elif roll < 0.92:
					var profit = gm.rand_int(150, 600) * skill
					return {"money_delta": profit, "xp_gain": 15,
						"log_text": "Earnings beat, IV crush didn't crush you. +$%d." % profit, "log_type": "money"}
				else:
					var profit = gm.rand_int(800, 2500) * skill
					return {"money_delta": profit, "xp_gain": 20,
						"log_text": "You caught the bottom of a 3x runner. +$%d tendies secured." % profit, "log_type": "money"},
		},
		{
			"id": "options_play",
			"label": "0DTE Options Gamble",
			"description": "Buy same-day-expiry call options. Either 10x or zero.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.trading
				var stake = min(gm.money, 200 + skill * 50)
				if gm.chance(0.32 + skill * 0.015):
					var profit = int(stake * (1.5 + randf() * 4))
					return {"money_delta": profit, "xp_gain": 15,
						"log_text": "0DTE printed. $%d in, $%d out." % [stake, profit], "log_type": "money"}
				return {"money_delta": -stake, "xp_gain": 8,
					"log_text": "0DTE went to zero. Theta gang ate $%d." % stake, "log_type": "danger"},
		},
		{
			"id": "pump_dump",
			"label": "Pump & Dump Microcap",
			"description": "Buy illiquid penny stock, hype it in Discord, dump.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.trading
				var profit = gm.rand_int(400, 1500) * skill
				if gm.chance(0.22):
					return {"money_delta": -gm.rand_int(200, 800), "heat_delta": 15, "xp_gain": 5,
						"log_text": "SEC opened an informal inquiry.", "log_type": "danger"}
				return {"money_delta": profit, "heat_delta": 4, "xp_gain": 18,
					"log_text": "Hyped $ZZZZ on Discord. Bagholders bought your bags for +$%d." % profit, "log_type": "money"},
		},
	]

# ============================================================
# GAMBLING
# ============================================================
static func _gambling_actions() -> Array:
	return [
		{
			"id": "slots",
			"label": "Slot Machine",
			"description": "Pull the lever. Mostly lose, sometimes win, rarely jackpot.",
			"cost": 1,
			"perform": func(gm):
				var roll = randf()
				if roll < 0.6:
					return {"money_delta": -50, "xp_gain": 4,
						"log_text": "Slots ate your $50. The lights are pretty, though.", "log_type": "danger"}
				elif roll < 0.9:
					var win = gm.rand_int(80, 250)
					return {"money_delta": win, "xp_gain": 6,
						"log_text": "Three cherries! +$%d." % win, "log_type": "money"}
				elif roll < 0.99:
					var win = gm.rand_int(800, 2500)
					return {"money_delta": win, "xp_gain": 10,
						"log_text": "MINOR JACKPOT! +$%d." % win, "log_type": "money"}
				else:
					var win = gm.rand_int(15000, 50000)
					return {"money_delta": win, "xp_gain": 20,
						"log_text": "MEGA JACKPOT! +$%d! Sirens, champagne, the works." % win, "log_type": "money"},
		},
		{
			"id": "roulette_red",
			"label": "Roulette — Bet Red",
			"description": "Bet $500 on red. Pays 1:1. 48.6% to win.",
			"cost": 1,
			"perform": func(gm):
				var stake = min(gm.money, 500)
				var spin = gm.rand_int(0, 36)
				var is_red = spin != 0 and [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36].has(spin)
				if is_red:
					return {"money_delta": stake, "xp_gain": 6,
						"log_text": "Spin landed %d (RED). +$%d." % [spin, stake], "log_type": "money"}
				return {"money_delta": -stake, "xp_gain": 4,
					"log_text": "Spin landed %s. Lost $%d." % [("0 GREEN" if spin == 0 else "%d BLACK" % spin), stake], "log_type": "danger"},
		},
		{
			"id": "blackjack_count",
			"label": "Count Cards at Blackjack",
			"description": "Sit at the $100-min table and count. If pit boss notices...",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.gambling
				var win_rate = 0.5 + skill * 0.025
				if gm.chance(0.18):
					return {"money_delta": -gm.rand_int(200, 600), "heat_delta": 6, "xp_gain": 5,
						"log_text": "Pit boss tapped your shoulder. 'Sir, you're no longer welcome here.'", "log_type": "danger"}
				if gm.chance(win_rate):
					var profit = gm.rand_int(200, 800) * skill
					return {"money_delta": profit, "xp_gain": 12,
						"log_text": "Counting paid off. +$%d across 4 shoes." % profit, "log_type": "money"}
				return {"money_delta": -gm.rand_int(150, 500), "xp_gain": 8,
					"log_text": "Count was off — bad shoe. -$%d." % gm.rand_int(150, 500), "log_type": "danger"},
		},
	]

# ============================================================
# DRUGS
# ============================================================
static func _drugs_actions() -> Array:
	return [
		{
			"id": "slang_bud",
			"label": "Slang a Bag of Bud",
			"description": "Low-stakes weed deals. $50 profit, low heat, builds street cred.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.drugs
				var profit = gm.rand_int(40, 90) * skill
				if gm.chance(0.07):
					return {"money_delta": 0, "heat_delta": 6, "rep_delta": -2, "xp_gain": 4,
						"log_text": "Buyer ghosted. Might've been a CI.", "log_type": "heat"}
				return {"money_delta": profit, "heat_delta": 2, "rep_delta": 1, "xp_gain": 10,
					"log_text": "Sold an eighth to a regular for $%d." % profit, "log_type": "money"},
		},
		{
			"id": "flip_pills",
			"label": "Flip a Bottle of Pills",
			"description": "Move prescription painkillers. Higher profit, higher heat.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.drugs
				var profit = gm.rand_int(300, 800) * skill
				if gm.chance(0.14):
					return {"money_delta": -gm.rand_int(100, 400), "heat_delta": 14, "xp_gain": 6,
						"log_text": "Buyer was wearing a wire. You bolted but lost the product.", "log_type": "danger"}
				return {"money_delta": profit, "heat_delta": 6, "rep_delta": 2, "xp_gain": 12,
					"log_text": "Moved a bottle of blues for $%d." % profit, "log_type": "money"},
		},
		{
			"id": "supply_run",
			"label": "Pick Up from the Plug",
			"description": "Drive 2 hours to the wholesale plug. Big risk, big supply drop.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.drugs
				var profit = gm.rand_int(1500, 4000) * skill
				if gm.chance(0.20):
					var bribe = gm.rand_int(300, 800)
					if gm.money > bribe + 200 and gm.chance(0.7):
						return {"money_delta": -bribe, "heat_delta": 8, "xp_gain": 8,
							"log_text": "Highway patrol pulled you over. Slipped the officer $%d." % bribe, "log_type": "heat"}
					return {"money_delta": -gm.rand_int(500, 1500), "heat_delta": 30, "xp_gain": 4,
						"log_text": "Got pulled over with product in the trunk. Couldn't talk your way out.", "log_type": "danger"}
				return {"money_delta": profit, "heat_delta": 8, "rep_delta": 5, "xp_gain": 20,
					"log_text": "Plug hooked you up. Flipped the whole zip in a day for +$%d." % profit, "log_type": "money"},
		},
	]

# ============================================================
# SCAM
# ============================================================
static func _scam_actions() -> Array:
	return [
		{
			"id": "phish_emails",
			"label": "Send Phishing Emails",
			"description": "Blast 10k fake 'Netflix' emails. ~0.3% click rate.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.scam
				if gm.chance(0.10):
					return {"money_delta": 0, "heat_delta": 5, "xp_gain": 5,
						"log_text": "Email provider flagged the domain.", "log_type": "heat"}
				var profit = gm.rand_int(80, 250) * skill
				return {"money_delta": profit, "heat_delta": 2, "xp_gain": 10,
					"log_text": "Got %d victims to log into your fake portal. Net: +$%d." % [gm.rand_int(3, 9), profit], "log_type": "money"},
		},
		{
			"id": "romance_scam",
			"label": "Run a Romance Scam",
			"description": "Catfish a lonely boomer for 2 weeks.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.scam
				if gm.chance(0.18):
					return {"money_delta": 0, "heat_delta": 8, "rep_delta": -1, "xp_gain": 4,
						"log_text": "Target's grandkid reverse-image-searched your pics. IC3 complaint filed.", "log_type": "heat"}
				var profit = gm.rand_int(300, 1200) * skill
				return {"money_delta": profit, "heat_delta": 4, "xp_gain": 14,
					"log_text": "'Margaret' sent $%d in Apple gift cards for 'her grandson's bail.'" % profit, "log_type": "money"},
		},
		{
			"id": "pig_butchering",
			"label": "Pig-Butchering Scheme",
			"description": "Weeks of 'crypto investment' grooming. FBI loves these.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.scam
				if gm.chance(0.28):
					return {"money_delta": -gm.rand_int(100, 500), "heat_delta": 18, "xp_gain": 6,
						"log_text": "Target reported to FBI IC3. They're pulling chat logs from Telegram.", "log_type": "danger"}
				var profit = gm.rand_int(2500, 8000) * skill
				return {"money_delta": profit, "heat_delta": 8, "rep_delta": 3, "xp_gain": 22,
					"log_text": "'Daniel' withdrew his 'crypto gains' — straight to your wallet. +$%d." % profit, "log_type": "money"},
		},
	]

# ============================================================
# ROBBERY
# ============================================================
static func _robbery_actions() -> Array:
	return [
		{
			"id": "snatch_phone",
			"label": "Snatch a Phone",
			"description": "Grab a tourist's iPhone off a cafe table. Quick $200, low heat.",
			"cost": 1,
			"perform": func(gm):
				var skill = gm.skills.robbery
				if gm.chance(0.15):
					return {"money_delta": 0, "heat_delta": 12, "xp_gain": 4,
						"log_text": "Tourist chased you down. Bystander filmed it. CCTV has your face.", "log_type": "danger"}
				var profit = gm.rand_int(100, 350) * skill
				return {"money_delta": profit, "heat_delta": 4, "rep_delta": 1, "xp_gain": 10,
					"log_text": "Snatched an iPhone 15 Pro, fenced for $%d." % profit, "log_type": "money"},
		},
		{
			"id": "burglary",
			"label": "Burglarize a House",
			"description": "Suburban home, owner is on a 2-week vacation.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.robbery
				if gm.chance(0.22):
					return {"money_delta": -gm.rand_int(100, 300), "heat_delta": 25, "xp_gain": 6,
						"log_text": "Neighbor's Ring camera caught your face. You're a person of interest.", "log_type": "danger"}
				var profit = gm.rand_int(1500, 5000) * skill
				return {"money_delta": profit, "heat_delta": 10, "rep_delta": 4, "xp_gain": 18,
					"log_text": "Jewelry, electronics, cash in a sock drawer. Fenced for +$%d." % profit, "log_type": "money"},
		},
		{
			"id": "armed_robbery",
			"label": "Arm-Rob a Corner Store",
			"description": "Mask up, walk in with a replica Glock. $5-15k score.",
			"cost": 3,
			"perform": func(gm):
				var skill = gm.skills.robbery
				if gm.chance(0.35):
					return {"money_delta": 0, "heat_delta": 50, "xp_gain": 4,
						"log_text": "Clerk hit the silent alarm. Cops were 90 seconds out. You escaped but they got your plates.", "log_type": "danger"}
				var profit = gm.rand_int(4000, 14000) * skill
				return {"money_delta": profit, "heat_delta": 18, "rep_delta": 8, "xp_gain": 25,
					"log_text": "Walked out with $%d in small bills." % profit, "log_type": "money"},
		},
	]

# ============================================================
# TAX FRAUD
# ============================================================
static func _taxfraud_actions() -> Array:
	return [
		{
			"id": "setup_tax_fraud",
			"label": "Set Up Fake Tax Return Scheme",
			"description": "Fabricate 12 dependents and $80k of fake expenses. One-time setup.",
			"cost": 3,
			"perform": func(gm):
				if gm.tax_setup:
					return {"log_text": "Already set up. Run 'Harvest Refund' instead.", "log_type": "info"}
				gm.tax_setup = true
				return {"money_delta": -300, "heat_delta": 4, "xp_gain": 15,
					"log_text": "Hired a 'creative accountant' off Craigslist. $300 fee. Refunds will accrue.", "log_type": "info", "extra": {"tax_setup": true}},
			"available": func(gm): return not gm.tax_setup,
			"unavailable_reason": "Already set up. Run 'Harvest Refund' instead.",
		},
		{
			"id": "harvest_refund",
			"label": "Harvest Tax Refund",
			"description": "File another batch of fraudulent returns. $1-3k per filing.",
			"cost": 1,
			"perform": func(gm):
				if not gm.tax_setup:
					return {"log_text": "Need to set up the scheme first.", "log_type": "info"}
				var skill = gm.skills.taxfraud
				if gm.chance(0.10):
					return {"money_delta": -gm.rand_int(500, 2000), "heat_delta": 20, "xp_gain": 6,
						"log_text": "IRS flagged your batch for audit. Lost $%d in 'fees' to your accountant." % gm.rand_int(500, 2000), "log_type": "danger"}
				var profit = gm.rand_int(1000, 3500) * skill
				return {"money_delta": profit, "heat_delta": 3, "xp_gain": 12,
					"log_text": "Filed 4 fake returns. Treasury deposited $%d. Suck it, Uncle Sam." % profit, "log_type": "money"},
			"available": func(gm): return gm.tax_setup,
			"unavailable_reason": "Set up the scheme first.",
		},
	]

# ============================================================
# WIRE FRAUD
# ============================================================
static func _wirefraud_actions() -> Array:
	return [
		{
			"id": "fake_invoice",
			"label": "Send Fake Vendor Invoice",
			"description": "Spoof a vendor's email, send a $15k 'past due' invoice.",
			"cost": 2,
			"perform": func(gm):
				var skill = gm.skills.wirefraud
				if gm.chance(0.22):
					return {"money_delta": 0, "heat_delta": 15, "xp_gain": 5,
						"log_text": "AP clerk called the real vendor. FBI Cyber Division has your wire info.", "log_type": "danger"}
				var profit = gm.rand_int(8000, 22000) * skill
				return {"money_delta": profit, "heat_delta": 6, "rep_delta": 3, "xp_gain": 20,
					"log_text": "AP paid the fake invoice without checking. +$%d hit your mule account." % profit, "log_type": "money"},
		},
		{
			"id": "ceo_fraud",
			"label": "CEO Impersonation Wire",
			"description": "Pressure the CFO into wiring $50-150k for an 'acquisition.'",
			"cost": 3,
			"perform": func(gm):
				var skill = gm.skills.wirefraud
				if gm.chance(0.38):
					return {"money_delta": 0, "heat_delta": 30, "xp_gain": 4,
						"log_text": "CFO smelled something off, called the CEO directly. Secret Service opened a file.", "log_type": "danger"}
				var profit = gm.rand_int(40000, 130000) * skill
				return {"money_delta": profit, "heat_delta": 12, "rep_delta": 6, "xp_gain": 30,
					"log_text": "CFO wired $%d for the 'urgent acquisition.' Money is now bouncing through 4 countries." % profit, "log_type": "money"},
		},
	]
