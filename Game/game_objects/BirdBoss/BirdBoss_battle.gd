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
        
func execute_action(task_queue: AsyncTaskQueue, action: BattleAttackData, target: Combatant) -> void:
    if action.unique_name == PartyManager.bird_boss_attack_name:
        attack_animated_sprite_2d.global_position = target.get_hit_target_marker().global_position - Vector2(10,0)
        attack_animated_sprite_2d.visible = true
        attack_animated_sprite_2d.play("slash_attack")
        battle_scene.deal_damage_to_combatant(target, action.base_damage, task_queue)
        await attack_animated_sprite_2d.animation_finished
        attack_animated_sprite_2d.visible = visible
        attack_animated_sprite_2d.play("default")
        if not task_queue.is_finished():
            await task_queue.all_completed
        attack_animated_sprite_2d.visible = false
    elif action.unique_name == PartyManager.player_use_item_name:
        var does_nothing_label := SceneHelpers.create_default_label(Color.RED, 8, "Item does nothing")
        does_nothing_label.global_position = get_hit_target_marker().global_position - Vector2(50, 20)
        get_tree().root.add_child(does_nothing_label)
        await get_tree().create_timer(1.5).timeout
        does_nothing_label.queue_free()
        
func get_available_actions() -> Array[BattleAttackData]:
  return combat_stats.battle_attacks

func take_damage(task_queue: AsyncTaskQueue, amount: int) -> void:
    super.take_damage(task_queue, amount)
    task_queue.add_task_ref("charecter_damage_anim")
    animated_sprite_2d.play("taking_damage")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.play("Idle")
    task_queue.release_task_ref("charecter_damage_anim")
    if is_dead():
        modulate.a = .2
        rotate(-PI / 2)
        animated_sprite_2d.play("dead")
    else:
        animated_sprite_2d.play("Idle")
    
func get_stats() -> PlayerBattleStats:
    return combat_stats

func request_turn_action(task_queue: AsyncTaskQueue) -> Combatant.BattleTurnResult:
    var actions := get_available_actions()
    var rand_action_index := randi_range(0, actions.size() - 1)
    var select_action_ui := battle_scene.battle_select_action_scene
    await select_action_ui.force_select(actions, rand_action_index)
    
    var targets: Array[Combatant] = battle_scene.alive_players
    var rand_target_index := randi_range(0, targets.size() - 1)
    battle_scene.enter_target_selection(self)
    var target_of_all_players := battle_scene.player_combatants.find(battle_scene.alive_players[rand_target_index])
    await battle_scene.force_select_target(target_of_all_players)
    
    return Combatant.BattleTurnResult.new(actions[rand_action_index], targets[rand_target_index])
