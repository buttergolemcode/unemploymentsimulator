# VehicleData.gd — Vehicle definitions + spawning
class_name VehicleData
extends RefCounted

const VEHICLE_POSITIONS: Array = [
	{"x": 8, "z": 4, "yaw": 0, "color": "#dc2626"},
	{"x": -8, "z": 6, "yaw": 3.14, "color": "#2563eb"},
	{"x": 4, "z": -8, "yaw": 1.57, "color": "#16a34a"},
	{"x": -20, "z": -25, "yaw": 0, "color": "#facc15"},
	{"x": -38, "z": -10, "yaw": 1.57, "color": "#7c3aed"},
	{"x": 22, "z": -30, "yaw": -1.57, "color": "#f97316"},
	{"x": 38, "z": -8, "yaw": 0, "color": "#06b6d4"},
	{"x": -22, "z": 22, "yaw": 3.14, "color": "#ec4899"},
	{"x": -38, "z": 10, "yaw": 0, "color": "#fbbf24"},
	{"x": 22, "z": 28, "yaw": -1.57, "color": "#34d399"},
	{"x": 42, "z": 10, "yaw": 3.14, "color": "#a78bfa"},
]

static func get_positions() -> Array:
	return VEHICLE_POSITIONS
