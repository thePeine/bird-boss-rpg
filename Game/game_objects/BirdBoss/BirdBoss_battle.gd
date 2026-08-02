extends Combatant

@onready var animated_sprite_2d: AnimatedSprite2D = $FootOffset/AnimatedSprite2D
@onready var attack_animated_sprite_2d: AnimatedSprite2D = $AttackAnimatedSprite2D

var combat_stats: PlayerBattleStats

func _init() -> void:
    combat_stats = PartyManager.create_new_bird_boss_battle_stats()

func _ready() -> void:
    attack_animated_sprite_2d.visible = false

func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker
        
func execute_action(action: BattleAttackData, target: Combatant) -> void:
    if action.unique_name == PartyManager.bird_boss_attack_name:
        attack_animated_sprite_2d.global_position = target.get_hit_target_marker().global_position - Vector2(10,0)
        attack_animated_sprite_2d.visible = true
        attack_animated_sprite_2d.play("slash_attack")
        await battle_scene.deal_damage_to_combatant(target, action.base_damage)
        if attack_animated_sprite_2d.is_playing():
            await attack_animated_sprite_2d.animation_finished
        attack_animated_sprite_2d.visible = visible
        attack_animated_sprite_2d.play("default")
        turn_completed.emit({})
    elif action.unique_name == PartyManager.player_use_item_name:
        var does_nothing_label := SceneHelpers.create_default_label(Color.RED, 8, "Item does nothing")
        does_nothing_label.global_position = get_hit_target_marker().global_position - Vector2(50, 20)
        get_tree().root.add_child(does_nothing_label)
        await get_tree().create_timer(1.5).timeout
        does_nothing_label.queue_free()
        turn_completed.emit({})
        
func get_available_actions() -> Array[BattleAttackData]:
  return combat_stats.battle_attacks

func take_damage(amount: int) -> Variant:
    animated_sprite_2d.play("taking_damage")
    await super.take_damage(amount)
    if animated_sprite_2d.is_playing():
        await animated_sprite_2d.animation_finished
    animated_sprite_2d.play("Idle")
    return null
    
func your_turn_started() -> void:
    var actions := get_available_actions()
    var rand_action_index := randi_range(0, actions.size() - 1)
    await battle_scene.battle_select_action_scene.force_select(actions[rand_action_index])
    
    var targets: Array[Combatant] = battle_scene.alive_player_combatants
    var rand_target_index := randi_range(0, targets.size() - 1)
    battle_scene.force_select_target(targets[rand_target_index])


func get_stats() -> PlayerBattleStats:
    return combat_stats
