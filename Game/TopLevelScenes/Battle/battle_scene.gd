class_name BattleScene 
extends Node2D

enum BattleSceneState { INACTIVE, INTRO, RUNNING, BATTLE_COMPLETED }

var _state: BattleSceneState = BattleSceneState.INACTIVE

@onready var bottom_panel: Control = $CanvasLayer/BottomPanel
@onready var active_combatant_indicator: Sprite2D = $ActiveCombatantIndicator
@onready var target_selector: AnimatedSprite2D = $TargetSelector
@onready var battle_transition: AnimatedSprite2D = $BattleTransition
@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var combatants_parent_node: Node2D = $Combantants
@onready var battle_select_action_scene: battle_select_action = $battle_select_action
@onready var camera_2d: battle_camera = $Camera2D

@onready var player_spawn_markers: Array[Marker2D] = [$PlayerSpawn_1, $PlayerSpawn_2, $PlayerSpawn_3, $PlayerSpawn_4]
@onready var enemy_spawn_markers: Array[Marker2D] = [$EnemySpawn_1, $EnemySpawn_2, $EnemySpawn_3, $EnemySpawn_4]
@onready var p_1_stats: RichTextLabel = $CanvasLayer/BottomPanel/TextureRect/P1Stats
@onready var p_2_stats: RichTextLabel = $CanvasLayer/BottomPanel/TextureRect/P2Stats

const P1_COMBATANT_SCENE = preload("res://game_objects/Player1/P1_Battle.tscn")
const BIRD_BOSS_COMBATANT_SCENE = preload("res://game_objects/BirdBoss/BirdBoss_Battle.tscn")

var turn_queue: Array[Combatant] = []
var player_combatants: Array[Combatant] = []
var enemy_combatants: Array[Combatant] = []

var alive_players : Array[Combatant]:
    get:
        return player_combatants.filter(func(c: Combatant) -> bool: return not c.is_dead())
var alive_enemies : Array[Combatant]:
    get:
        return enemy_combatants.filter(func(c: Combatant) -> bool: return not c.is_dead())

var active_combatant_index: int = 0

var active_combatant: Combatant:
    get: return turn_queue[active_combatant_index]

signal target_selection_confirmed(target: Combatant)

func _ready() -> void:
    _initialize_indicator_tween()

var battle_background_texture: Texture2D = null

func setup_battle(background_texture: Texture2D, player_party: Array[PlayerBattleStats.PlayerType], enemy_party: Array[PlayerBattleStats.PlayerType]) -> void:
    battle_background_texture = background_texture
    
    for i : int in min(player_party.size(), player_spawn_markers.size()):
        var c := _instantiate_combatant(player_party[i], player_spawn_markers[i], true)
        if c: player_combatants.push_back(c)
            
    for i : int in min(enemy_party.size(), enemy_spawn_markers.size()):
        var c := _instantiate_combatant(enemy_party[i], enemy_spawn_markers[i], false)
        if c: enemy_combatants.push_back(c)
            
    _run_intro_sequence()


func _run_intro_sequence() -> void:
    _state = BattleSceneState.INTRO
    bottom_panel.visible = false
    combatants_parent_node.visible = false
    battle_transition.visible = true
    battle_transition.play("default")
    
    var has_switched_background_yet := false
    
    while battle_transition.is_playing():
        if not has_switched_background_yet and battle_transition.frame == 7:
            has_switched_background_yet = true
            background_sprite.texture = battle_background_texture
            bottom_panel.visible = true

            
        await get_tree().process_frame
        
    battle_transition.visible = false
    combatants_parent_node.visible = true
    
    _state = BattleSceneState.RUNNING
    active_combatant_index = 0
    _execute_turn_loop()


func _execute_turn_loop() -> void:
    while _state == BattleSceneState.RUNNING:
        if active_combatant.is_dead():
            _advance_turn_index()
            continue
            
        var marker_pos: Vector2 = active_combatant.get_active_combatant_marker().global_position
        active_combatant_indicator.global_position = marker_pos
        battle_select_action_scene.global_position = marker_pos
        active_combatant_indicator.visible = true
        
        # Build a single queue for this entire turn.  Anyone in the chain can add to this, and we will wait for completion
        # this was mainly added for things like if I deal damage to an opponent, I don't want to relinquish my turn
        # until the damage is done (Animation completed, ui updated, etc).  If these aren't in sync, turns will look wrong
        var task_queue := AsyncTaskQueue.new()
        
        # HAND CONTROL OVER TO COMBATANT: Completely freeze this loop until it returns details
        var turn_summary: Combatant.BattleTurnResult = await active_combatant.request_turn_action(task_queue)
        await active_combatant.execute_action(
            task_queue, 
            turn_summary.action,
            turn_summary.target
        )
        
        if not task_queue.is_finished():
            await task_queue.all_completed
        active_combatant_indicator.visible = false
        _advance_turn_index()


func _advance_turn_index() -> void:
    if turn_queue.is_empty(): return
    active_combatant_index = posmod(active_combatant_index + 1, turn_queue.size())

func deal_damage_to_combatant(target: Combatant, damage: int, task_queue: AsyncTaskQueue) -> void:
    camera_2d.add_shake(3)
    target.take_damage(task_queue, damage)

func enter_target_selection(requester: Combatant) -> void:
    target_selector.visible = true
    active_combatant_indicator.visible = false


func get_user_target_selection(requester: Combatant) -> Combatant:
    var targets := enemy_combatants if requester in player_combatants else player_combatants
    var current_selection := 0
    
    target_selector.global_position = targets[current_selection].get_active_combatant_marker().global_position
    
    while true:
        if Input.is_action_just_pressed('ui_right'):
            current_selection = posmod(current_selection + 1, targets.size())
            target_selector.global_position = targets[current_selection].get_active_combatant_marker().global_position
        elif Input.is_action_just_pressed('ui_left'):
            current_selection = posmod(current_selection - 1, targets.size())
            target_selector.global_position = targets[current_selection].get_active_combatant_marker().global_position
        elif Input.is_action_just_pressed('ui_accept'):
            break
        await get_tree().process_frame
        
    target_selector.visible = false
    return targets[current_selection]

func force_select_target(index_to_select: int) -> void:
    
    if index_to_select < 0:
        push_error("called force_select on an action that didn't exist on that player....just skip it")
        return
    if alive_players.size() == 0:
        push_error("No available targets?  How did you get here?")
        return
    
    var first_alive_player := alive_players[0]    
    var current_selection := player_combatants.find(first_alive_player)
    target_selector.global_position = player_combatants[current_selection].get_active_combatant_marker().global_position
    
    await get_tree().create_timer(0.5).timeout
    if not index_to_select == current_selection:
        var diff : int = abs(index_to_select - current_selection)
        var direction := -1 if index_to_select < current_selection else 1
        for i in range(diff):
            current_selection = posmod(current_selection + direction, player_combatants.size())
            target_selector.global_position = player_combatants[current_selection].get_active_combatant_marker().global_position
            await get_tree().create_timer(1).timeout
    
    target_selector.visible = false

func _instantiate_combatant(type: PlayerBattleStats.PlayerType, marker: Marker2D, is_player: bool) -> Combatant:
    var combatant: Combatant = null
    match type:
        PlayerBattleStats.PlayerType.P1:
            var combat_casted : p1_combatant= P1_COMBATANT_SCENE.instantiate() as p1_combatant
            combat_casted.party_member_name = PartyManager.P1_Name
            combat_casted.stats_updated.connect(_on_p1_stats_changed)
            _on_p1_stats_changed(combat_casted)
            combatant = combat_casted
        PlayerBattleStats.PlayerType.P2:
            var combat_casted : p1_combatant= P1_COMBATANT_SCENE.instantiate() as p1_combatant
            combat_casted.party_member_name = PartyManager.P2_Name
            combat_casted.stats_updated.connect(_on_p2_stats_changed)
            _on_p2_stats_changed(combat_casted)
            combatant = combat_casted
        PlayerBattleStats.PlayerType.BirdBoss:
            combatant = BIRD_BOSS_COMBATANT_SCENE.instantiate()

    if not combatant: return null

    combatant.battle_scene = self
    combatants_parent_node.add_child(combatant)
    combatant.position = marker.position
    turn_queue.push_back(combatant)
    
    combatant.died.connect(_on_combatant_died)
    return combatant


func _on_combatant_died(combatant: Combatant) -> void:
    
    if combatant in player_combatants and alive_players.is_empty():
        _terminate_match("You died!\nMaybe retry or something!!")
    elif combatant in enemy_combatants and alive_enemies.is_empty():
        _terminate_match("Congratulations!\nYou won!!")


func _terminate_match(message: String) -> void:
    _state = BattleSceneState.BATTLE_COMPLETED
    var label := SceneHelpers.create_default_label(Color.BLACK, 8, message)
    label.global_position = Vector2(50, 50)
    get_tree().root.add_child(label)
    
    await get_tree().create_timer(1.5).timeout
    label.queue_free()
    BattleManager.battle_manager_end_battle()


func _initialize_indicator_tween() -> void:
    var tween := create_tween().set_loops()
    tween.tween_property(active_combatant_indicator, "modulate:a", 0.3, 0.6)
    tween.tween_property(active_combatant_indicator, "modulate:a", 1.0, 0.6)


func _on_p1_stats_changed(combatant: Combatant) -> void:
    var stats := combatant.get_stats()
    p_1_stats.text = "HP: %d\nPP: %d" % [stats.current_health, stats.cur_pp]

func _on_p2_stats_changed(combatant: Combatant) -> void:
    var stats := combatant.get_stats()
    p_2_stats.text = "HP: %d\nPP: %d" % [stats.current_health, stats.cur_pp]
