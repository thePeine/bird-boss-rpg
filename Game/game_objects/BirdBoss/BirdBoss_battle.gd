extends Combatant

@onready var animated_sprite_2d: AnimatedSprite2D = $FootOffset/AnimatedSprite2D


func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker
        
func _physics_process(delta: float) -> void:
    pass

func execute_action(action: BattleAttackData, target: Combatant) -> void:
    if action.unique_name == PartyManager.bird_boss_attack_name:
        print("BOSS ATTACK")
    elif action.unique_name == PartyManager.player_use_item_name:
        var does_nothing_label := Label.new()
        does_nothing_label.add_theme_font_override("font", GLOBAL_CONST.RESOURCES.PIXEL_FONT)
        does_nothing_label.add_theme_font_size_override("font_size", 8)
        does_nothing_label.set("theme_override_colors/font_color", Color.RED)        
        does_nothing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        does_nothing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        does_nothing_label.global_position = get_hit_target_marker().global_position
        does_nothing_label.text = "Item does nothing"
        does_nothing_label.position -= Vector2(50, 20)
        get_tree().root.add_child(does_nothing_label)
        await get_tree().create_timer(1.5).timeout
        does_nothing_label.queue_free()
        turn_completed.emit({})
        
func get_available_actions() -> Array[BattleAttackData]:
  return PartyManager.get_party_member(PartyManager.BirdBoss_Name).battle_attacks

func take_damage(amount: int) -> void:
    super.take_damage(amount)
    animated_sprite_2d.play("taking_damage")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.play("Idle")

func is_dead() -> bool:
    return false

func your_turn_started(battle_scene: BattleScene) -> void:
    var actions := get_available_actions()
    #await battle_scene.battle_select_action.force_select(actions[randi_range(0, actions.size() - 1) ])
    await battle_scene.battle_select_action.force_select(actions[1 ])
    
    var targets := battle_scene.player_combarants
    #battle_scene.force_select_target(targets[randi_range(0, targets.size() - 1)])
    await battle_scene.force_select_target(targets[1])
    
