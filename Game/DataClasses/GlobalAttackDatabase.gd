class_name AttackDatabase
extends Node

@export var attack_list: Dictionary[String, BattleAttackData] = {}

func get_attack(unique_name: String) -> BattleAttackData:
    return attack_list.get(unique_name)
