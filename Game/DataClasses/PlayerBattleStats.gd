class_name PlayerBattleStats
extends Resource

enum PlayerType {NONE, P1, P2, BirdBoss}

@export var max_health: int = 100
@export var current_health: int = 100
@export var level: int = 1

@export var battle_attacks: Array[BattleAttackData] = []
@export var type: PlayerType = PlayerType.NONE
 
