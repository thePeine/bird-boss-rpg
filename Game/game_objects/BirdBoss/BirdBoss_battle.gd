extends Combatant

@onready var animated_sprite_2d: AnimatedSprite2D = $FootOffset/AnimatedSprite2D


func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker
        
func _physics_process(delta: float) -> void:
    pass

func execute_action(action: BattleAttackData, target: Combatant) -> void:
     print("Executing action " + action.display_string + " on target " + target.name)
    
func get_available_actions() -> Array[BattleAttackData]:
  return PartyManager.get_party_member(PartyManager.BirdBoss_Name).battle_attacks

func take_damage(amount: int) -> void:
    super.take_damage(amount)
    animated_sprite_2d.play("taking_damage")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.play("Idle")

func is_dead() -> bool:
    return false
