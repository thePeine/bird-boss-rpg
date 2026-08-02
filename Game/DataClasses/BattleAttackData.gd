class_name BattleAttackData
extends Resource

@export var unique_name: String = ""
@export var display_string: String = ""
@export var selection_texture: Texture2D
@export var pp_cost: int = 0
@export var base_damage: int = 0

func _init(un : String, ds: String, tex : Texture2D, pp: int, bd: int) -> void:
    unique_name = un
    display_string = ds
    selection_texture = tex
    pp_cost = pp
    base_damage = bd
