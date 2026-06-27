# VehicleData.gd — Vehicle definitions + spawning
class_name VehicleData
extends RefCounted

# Maps car model name -> FBX path in assets
const CAR_MODELS: Dictionary = {
	"NormalCar1": "res://assets/quaternius_cars/FBX/NormalCar1.fbx",
	"NormalCar2": "res://assets/quaternius_cars/FBX/NormalCar2.fbx",
	"SportsCar":  "res://assets/quaternius_cars/FBX/SportsCar.fbx",
	"SportsCar2": "res://assets/quaternius_cars/FBX/SportsCar2.fbx",
	"SUV":        "res://assets/quaternius_cars/FBX/SUV.fbx",
	"Taxi":       "res://assets/quaternius_cars/FBX/Taxi.fbx",
	"Cop":        "res://assets/quaternius_cars/FBX/Cop.fbx",
}

const VEHICLE_POSITIONS: Array = [
	# Downtown (+100..+800) — main avenues
	{"x": 250,  "z": 50,   "yaw": 0,    "model": "NormalCar1"},
	{"x": 350,  "z": -50,  "yaw": 1.57, "model": "Taxi"},
	{"x": 450,  "z": 100,  "yaw": 3.14, "model": "SportsCar"},
	{"x": 550,  "z": -100, "yaw": 0,    "model": "NormalCar2"},
	{"x": 650,  "z": 50,   "yaw": -1.57,"model": "SUV"},
	# Harbor — near piers
	{"x": 900,  "z": 0,    "yaw": 0,    "model": "NormalCar1"},
	{"x": 1000, "z": 100,  "yaw": 1.57, "model": "SportsCar2"},
	# Industrial — warehouse area
	{"x": -200, "z": -100, "yaw": 0,    "model": "SUV"},
	{"x": -400, "z": 50,   "yaw": 3.14, "model": "NormalCar2"},
	# Suburbs — residential streets
	{"x": -700, "z": -100, "yaw": 0,    "model": "NormalCar1"},
	{"x": -800, "z": 200,  "yaw": 1.57, "model": "SportsCar"},
]

static func get_positions() -> Array:
	return VEHICLE_POSITIONS

static func get_model_path(model_name: String) -> String:
	return CAR_MODELS.get(model_name, "")
