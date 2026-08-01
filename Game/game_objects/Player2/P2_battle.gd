extends Combatant


func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker
        
func _physics_process(delta: float) -> void:
    pass

func execute_action(action: BattleAttackData, target: Combatant) -> void:
     print("Executing action " + action.display_string + " on target " + target.name)
    
func get_available_actions() -> Array[BattleAttackData]:
    return [GS.KnownAttacks.get_attack("PlayerRegPunch"), GS.KnownAttacks.get_attack("PlayerUseItem"), GS.KnownAttacks.get_attack("PlayerBroAttack")]

func take_damage(amount: int) -> void:
    super.take_damage(amount)
    return

func is_dead() -> bool:
    return false
