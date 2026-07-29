@abstract
class_name Combatant
extends CharacterBody2D


signal turn_completed(action_data: Dictionary)
signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 100
@export var current_health: int = 100
@export var speed: int = 10

@abstract func on_turn_start() -> void

func take_damage(amount: int) -> void:
    current_health = clampi(current_health - amount, 0, max_health)
    health_changed.emit(current_health, max_health)
    if is_dead():
        died.emit()

func is_dead() -> bool:
    return current_health <= 0
