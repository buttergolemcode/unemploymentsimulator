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
	{"x": 8,   "z": 4,   "yaw": 0,     "model": "NormalCar1"},
	{"x": -8,  "z": 6,   "yaw": 3.14,  "model": "NormalCar2"},
	{"x": 4,   "z": -8,  "yaw": 1.57,  "model": "SportsCar"},
	{"x": -20, "z": -25, "yaw": 0,     "model": "SportsCar2"},
	{"x": -38, "z": -10, "yaw": 1.57,  "model": "SUV"},
	{"x": 22,  "z": -30, "yaw": -1.57, "model": "Taxi"},
	{"x": 38,  "z": -8,  "yaw": 0,     "model": "NormalCar1"},
	{"x": -22, "z": 22,  "yaw": 3.14,  "model": "NormalCar2"},
	{"x": -38, "z": 10,  "yaw": 0,     "model": "SportsCar"},
	{"x": 22,  "z": 28,  "yaw": -1.57, "model": "SportsCar2"},
	{"x": 42,  "z": 10,  "yaw": 3.14,  "model": "SUV"},
]

static func get_positions() -> Array:
	return VEHICLE_POSITIONS

static func get_model_path(model_name: String) -> String:
	return CAR_MODELS.get(model_name, "")
