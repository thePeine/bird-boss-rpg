class_name BattleScene
extends Node2D

@onready var player_spawn_1: Marker2D = $PlayerSpawn_1
@onready var player_spawn_2: Marker2D = $PlayerSpawn_2
@onready var player_spawn_3: Marker2D = $PlayerSpawn_3
@onready var player_spawn_4: Marker2D = $PlayerSpawn_4
@onready var enemy_spawn_1: Marker2D = $EnemySpawn_1
@onready var enemy_spawn_2: Marker2D = $EnemySpawn_2
@onready var enemy_spawn_3: Marker2D = $EnemySpawn_3
@onready var enemy_spawn_4: Marker2D = $EnemySpawn_4

@onready var background_sprite: Sprite2D = $BackgroundSprite
@onready var combatants_parent_node: Node2D = $Combantants

@onready var player_spawn_markers: Array[Marker2D] = [player_spawn_1, player_spawn_2, player_spawn_3, player_spawn_4]
@onready var enemy_spawn_markers: Array[Marker2D] = [enemy_spawn_1, enemy_spawn_2, enemy_spawn_3, enemy_spawn_4]

const P1_COMBATANT_SCENE =          preload("res://game_objects/Player1/P1_Battle.tscn")
const P2_COMBATANT_SCENE =          preload("res://game_objects/Player2/P2_Battle.tscn")
const BIRD_BOSS_COMBATANT_SCENE =   preload("res://game_objects/BirdBoss/BirdBoss_Battle.tscn")

var turn_queue: Array[Combatant] = []
var active_combatant_index: int
var active_combatant: Combatant:
    get:
        return turn_queue[active_combatant_index]
        
func _instantiate_and_add_combatant_from_type(player_type: PlayerBattleStats.PlayerType, location_marker: Marker2D) -> void:
    var combatant: Combatant = null
    
    match player_type:
        PlayerBattleStats.PlayerType.NONE:
            push_error("Can't have a type == NONE.  I don't know how to create that")
        PlayerBattleStats.PlayerType.P1:
            combatant = P1_COMBATANT_SCENE.instantiate() as Combatant
        PlayerBattleStats.PlayerType.P2:
            combatant = P2_COMBATANT_SCENE.instantiate() as Combatant
        PlayerBattleStats.PlayerType.BirdBoss:
            combatant = BIRD_BOSS_COMBATANT_SCENE.instantiate() as Combatant
    
    if not combatant:
        push_error("Don't know how to instantiate combantant of type: " + str(player_type))
        return
    
    if combatant:
        combatants_parent_node.add_child(combatant)
        combatant.position = location_marker.position
        turn_queue.push_back(combatant)
    
func _ready() -> void:
    pass
    
func setup_battle(background_texture: Texture2D, player_party_data: Array[PlayerBattleStats.PlayerType], enemy_party_data: Array[PlayerBattleStats.PlayerType]) -> void:
    background_sprite.texture = background_texture
    for i in range(player_party_data.size()):
        _instantiate_and_add_combatant_from_type(player_party_data[i], player_spawn_markers[i])
    
    for i in range(enemy_party_data.size()):
        _instantiate_and_add_combatant_from_type(enemy_party_data[i], enemy_spawn_markers[i])
    
    active_combatant_index = 0
    active_combatant.on_turn_start()

func execute_next_turn() -> void:
    if turn_queue.is_empty():
        return # Handle end of round or error
        
    active_combatant_index = posmod(active_combatant_index + 1, turn_queue.size())
    
    if active_combatant.is_dead():
        execute_next_turn()
        return
        
    active_combatant.on_turn_start()

func _on_combatant_turn_completed(action_data: Dictionary) -> void:
    if not active_combatant.is_dead():
        turn_queue.append(active_combatant)
        
    execute_next_turn()

func _on_combatant_died() -> void:
    # Check win/loss conditions here
    print("A combatant has fallen.")
