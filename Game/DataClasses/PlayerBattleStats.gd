class_name PlayerBattleStats
extends Resource

enum PlayerType {NONE, P1, P2, BirdBoss}

var max_health: int = 100
var current_health: int = 100
var max_pp: int = 100
var cur_pp: int = 100
var level: int = 1

var battle_attacks: Array[BattleAttackData] = []
var type: PlayerType = PlayerType.NONE

func _init(
    p_max_health: int = 100,
    p_current_health: int = 100,
    p_max_pp: int = 100,
    p_cur_pp: int = 100,
    p_level: int = 1,
    p_battle_attacks: Array[BattleAttackData] = [],
    p_type: PlayerType = PlayerType.NONE
) -> void:
    max_health = p_max_health
    current_health = p_current_health
    max_pp = p_max_pp
    cur_pp = p_cur_pp
    level = p_level
    battle_attacks = p_battle_attacks
    type = p_type
