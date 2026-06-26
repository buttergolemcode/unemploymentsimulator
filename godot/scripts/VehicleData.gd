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
        # Downtown (center) — main streets near intersections
        {"x": 0,    "z": -80,  "yaw": 0,     "model": "NormalCar1"},
        {"x": -80,  "z": 0,    "yaw": 1.57,  "model": "Taxi"},
        {"x": 80,   "z": 0,    "yaw": -1.57, "model": "SportsCar"},
        {"x": 0,    "z": 80,   "yaw": 3.14,  "model": "NormalCar2"},
        {"x": -150, "z": -50,  "yaw": 0,     "model": "SUV"},
        # Slums (SW) — parked on side streets
        {"x": -200, "z": 250,  "yaw": 0,     "model": "NormalCar1"},
        {"x": -280, "z": 320,  "yaw": 1.57,  "model": "NormalCar2"},
        # Industrial (NW) — warehouse district
        {"x": -250, "z": -200, "yaw": 0,     "model": "SUV"},
        {"x": -300, "z": -300, "yaw": 3.14,  "model": "SportsCar2"},
        # Harbor — near docks
        {"x": 230,  "z": -50,  "yaw": 0,     "model": "NormalCar1"},
        {"x": 280,  "z": 100,  "yaw": 1.57,  "model": "SportsCar"},
]

static func get_positions() -> Array:
        return VEHICLE_POSITIONS

static func get_model_path(model_name: String) -> String:
        return CAR_MODELS.get(model_name, "")
