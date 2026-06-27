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
	# NYC Downtown (center)
	{"x": 0, "z": 50, "yaw": 0, "model": "NormalCar1"},
	{"x": 100, "z": -50, "yaw": 1.57, "model": "Taxi"},
	{"x": -50, "z": 100, "yaw": 3.14, "model": "SportsCar"},
	{"x": 150, "z": 0, "yaw": -1.57, "model": "NormalCar2"},
	# Harbor (SE)
	{"x": 350, "z": 250, "yaw": 0, "model": "SUV"},
	{"x": 450, "z": 350, "yaw": 1.57, "model": "SportsCar2"},
	# Slums/Suburbs (W/NW)
	{"x": -300, "z": 0, "yaw": 0, "model": "NormalCar1"},
	{"x": -400, "z": -200, "yaw": 1.57, "model": "SUV"},
	# Portofino (NE)
	{"x": 300, "z": -300, "yaw": 0, "model": "SportsCar"},
	{"x": 200, "z": -400, "yaw": -1.57, "model": "NormalCar2"},
]

static func get_positions() -> Array:
	return VEHICLE_POSITIONS

static func get_model_path(model_name: String) -> String:
	return CAR_MODELS.get(model_name, "")
