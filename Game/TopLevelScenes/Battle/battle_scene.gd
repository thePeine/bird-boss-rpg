class_name BattleScene
extends Node2D

enum BattleSceneState {INACTIVE, INTRO, SELECTING_ACTION, SELECTING_TARGET, WAITING_FOR_ACTION, AUTOMATED}

var _state: BattleSceneState:
    get:
        return _state
    set(value):
        _state = value
        
        target_selector.visible = false
        active_combatant_indicator.visible = false
        battle_select_action.visible = false
        transition_circle.visible = false
        combatants_parent_node.visible = false
        bottom_panel.visible = true
        
        match _state:
            BattleSceneState.INTRO:
                transition_circle.visible = true
                transition_circle.scale = Vector2(.05, .05)
                bottom_panel.visible = false
            BattleSceneState.SELECTING_ACTION:
                combatants_parent_node.visible = true
                active_combatant_indicator.visible = true
                battle_select_action.set_visibility(true)
            BattleSceneState.SELECTING_TARGET:
                target_selector.visible = true
                combatants_parent_node.visible = true
            BattleSceneState.WAITING_FOR_ACTION:
                combatants_parent_node.visible = true
                pass
            BattleSceneState.INACTIVE:
                pass
                              
@onready var bottom_panel: Control = $CanvasLayer/BottomPanel

@onready var transition_circle: Sprite2D = $TransitionCircle
@onready var player_spawn_1: Marker2D = $PlayerSpawn_1
@onready var player_spawn_2: Marker2D = $PlayerSpawn_2
@onready var player_spawn_3: Marker2D = $PlayerSpawn_3
@onready var player_spawn_4: Marker2D = $PlayerSpawn_4
@onready var enemy_spawn_1: Marker2D = $EnemySpawn_1
@onready var enemy_spawn_2: Marker2D = $EnemySpawn_2
@onready var enemy_spawn_3: Marker2D = $EnemySpawn_3
@onready var enemy_spawn_4: Marker2D = $EnemySpawn_4
@onready var active_combatant_indicator: Sprite2D = $ActiveCombatantIndicator
@onready var target_selector: AnimatedSprite2D = $TargetSelector

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var combatants_parent_node: Node2D = $Combantants

@onready var player_spawn_markers: Array[Marker2D] = [player_spawn_1, player_spawn_2, player_spawn_3, player_spawn_4]
@onready var enemy_spawn_markers: Array[Marker2D] = [enemy_spawn_1, enemy_spawn_2, enemy_spawn_3, enemy_spawn_4]
@onready var battle_select_action: battle_select_action = $battle_select_action

const P1_COMBATANT_SCENE =          preload("res://game_objects/Player1/P1_Battle.tscn")
const BIRD_BOSS_COMBATANT_SCENE =   preload("res://game_objects/BirdBoss/BirdBoss_Battle.tscn")



var turn_queue: Array[Combatant] = []
var player_combarants: Array[Combatant] = []
var enemy_combarants: Array[Combatant] = []
var target_selection_index: int

var active_combatant_index: int
var active_combatant: Combatant:
    get:
        return turn_queue[active_combatant_index]
        
func _instantiate_and_add_combatant_from_type(player_type: PlayerBattleStats.PlayerType, location_marker: Marker2D) -> Combatant:
    var combatant: Combatant = null
    
    match player_type:
        PlayerBattleStats.PlayerType.NONE:
            push_error("Can't have a type == NONE.  I don't know how to create that")
        PlayerBattleStats.PlayerType.P1:
            var p1 := P1_COMBATANT_SCENE.instantiate() as p1_combatant
            p1.party_member_name = PartyManager.P1_Name
            combatant = p1
        PlayerBattleStats.PlayerType.P2:
            var p2 := P1_COMBATANT_SCENE.instantiate() as p1_combatant
            p2.party_member_name = PartyManager.P2_Name
            combatant = p2
        PlayerBattleStats.PlayerType.BirdBoss:
            combatant = BIRD_BOSS_COMBATANT_SCENE.instantiate() as Combatant
    
    if not combatant:
        push_error("Don't know how to instantiate combantant of type: " + str(player_type))
        return
    
    if combatant:
        combatants_parent_node.add_child(combatant)
        combatant.position = location_marker.position
        turn_queue.push_back(combatant)
        combatant.turn_completed.connect(_on_combatant_turn_completed)
    
    return combatant

func _ready() -> void:
    _state = BattleSceneState.INACTIVE
    var tween := create_tween().set_loops()
    tween.tween_property(active_combatant_indicator, "modulate:a", 0.3, 0.6) # Fade out over 1 second
    tween.tween_property(active_combatant_indicator, "modulate:a", 1.0, 0.6) # Fade in over 1 second

    battle_select_action.on_action_selected.connect(_on_battle_action_selected)
    battle_select_action.set_visibility(false)
    
func _on_battle_action_selected(action: BattleAttackData) -> void:
    _state = BattleSceneState.SELECTING_TARGET
    target_selection_index = 0 
    var target_array := enemy_combarants if active_combatant in player_combarants else player_combarants
    target_selector.global_position = target_array[target_selection_index].get_active_combatant_marker().global_position

func setup_battle(background_texture: Texture2D, player_party_data: Array[PlayerBattleStats.PlayerType], enemy_party_data: Array[PlayerBattleStats.PlayerType]) -> void:
    background_sprite.texture = background_texture
    for i in range(player_party_data.size()):
        var combatant := _instantiate_and_add_combatant_from_type(player_party_data[i], player_spawn_markers[i])
        player_combarants.push_back(combatant)
        
    for i in range(enemy_party_data.size()):
        var combatant :=_instantiate_and_add_combatant_from_type(enemy_party_data[i], enemy_spawn_markers[i])
        enemy_combarants.push_back(combatant)
    
    _state = BattleSceneState.INTRO


func execute_turn_start() -> void:
    battle_select_action.set_actions(active_combatant.get_available_actions(), active_combatant in enemy_combarants)
    battle_select_action.global_position = active_combatant.get_active_combatant_marker().global_position
    active_combatant_indicator.global_position = active_combatant.get_active_combatant_marker().global_position
    active_combatant.your_turn_started(self)
    _state = BattleSceneState.SELECTING_ACTION
    
func execute_next_turn() -> void:
    if turn_queue.is_empty():
        return # Handle end of round or error
        
    active_combatant_index = posmod(active_combatant_index + 1, turn_queue.size())
    
    if active_combatant.is_dead():
        execute_next_turn()
        return
        
    execute_turn_start()

func _on_combatant_turn_completed(action_data: Dictionary) -> void:
    execute_next_turn()

func _on_combatant_died() -> void:
    # Check win/loss conditions here
    print("A combatant has fallen.")

func force_select_target(target: Combatant) -> void:
    var index_to_select := player_combarants.find(target)
    if index_to_select == -1:
        push_error("called force_select on an action that didn't exist on that player....just skip it")
        execute_next_turn()
    
    await get_tree().create_timer(0.5).timeout
    if not index_to_select == target_selection_index:
        var diff : int = abs(index_to_select - target_selection_index)
        var direction := -1 if index_to_select < target_selection_index else 1
        for i in range(diff):
            target_selection_index = posmod(target_selection_index + direction, player_combarants.size())
            target_selector.global_position = player_combarants[target_selection_index].get_active_combatant_marker().global_position
            await get_tree().create_timer(0.5).timeout
    
    active_combatant.execute_action(battle_select_action.get_current_selected_item(), player_combarants[index_to_select])
    _state = BattleSceneState.WAITING_FOR_ACTION

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var input_event_key : InputEventKey = event as InputEvent
        if input_event_key.pressed and not input_event_key.echo:
            if input_event_key.physical_keycode == KEY_S:
                execute_next_turn()
                
func _process(delta: float) -> void:
    match _state:
        BattleSceneState.INTRO:
            transition_circle.scale += Vector2(delta, delta)
            if transition_circle.scale.x >=1 and transition_circle.scale.y >=1:
                transition_circle.scale = Vector2(1,1)
                _state = BattleSceneState.SELECTING_ACTION
                active_combatant_index = 0
                execute_turn_start()
        BattleSceneState.SELECTING_ACTION:
            return
        BattleSceneState.AUTOMATED:
            return
        BattleSceneState.SELECTING_TARGET:
            if active_combatant in enemy_combarants:
                return
            var target_array := enemy_combarants if active_combatant in player_combarants else player_combarants
            if Input.is_action_just_pressed('ui_accept'):
                active_combatant.execute_action(battle_select_action.get_current_selected_item(), target_array[target_selection_index])
                _state = BattleSceneState.WAITING_FOR_ACTION
                return
                
            var new_target_selection_index := target_selection_index
            if Input.is_action_just_pressed('ui_right'):
                new_target_selection_index = posmod(target_selection_index + 1, target_array.size())
            elif Input.is_action_just_pressed('ui_left'):
                new_target_selection_index = posmod(target_selection_index - 1, target_array.size())
            
                
            if not new_target_selection_index == target_selection_index:
                target_selection_index = new_target_selection_index
                target_selector.global_position = target_array[target_selection_index].get_active_combatant_marker().global_position
