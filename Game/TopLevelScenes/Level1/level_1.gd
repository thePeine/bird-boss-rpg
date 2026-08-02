extends Node2D

enum Level1_State {Overworld, Dialog, ForceMovingPlayers, Battle}

@onready var p1: PlayerCharacter = $P1
@onready var p2: PlayerCharacterP2 = $P2
@export var battle_background: Texture2D;
@onready var dialog_node_2d: DialogNode2D = $Dialog
@onready var p_1_dialog_position_bird_boss: Marker2D = $P1DialogPosition_BirdBoss
@onready var p_2_dialog_position_bird_boss: Marker2D = $P2DialogPosition_BirdBoss

var _state: Level1_State

var _intro_dialog_data: DialogData
var _waiting_for_force_move: Array[CharacterBody2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    p1.collide_with_enemy.connect(_on_collide_with_enemy)
    p1.force_move_completed.connect(_on_force_move_completed)
    p2.force_move_completed.connect(_on_force_move_completed)
    _state = Level1_State.Overworld
    _intro_dialog_data = DialogData.new()
    dialog_node_2d.visible = false
    
    var path := "res://DataFiles/PreBossFightDialog.json"
    if not FileAccess.file_exists(path):
       push_error("Coudln't load lineup from disk")
       return
    
    var parsed_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed_data is Dictionary:
        var raw_messages: Variant = parsed_data.get("messages")
        if raw_messages is Array:
            var parsed_messages: Array = raw_messages
            for message: Dictionary in parsed_messages:
                var dialog_message := DialogData.DialogMessage.new()
                dialog_message.owner_name = message["owner_name"]
                dialog_message.message_text = message["message_text"]
                _intro_dialog_data.messages.push_back(dialog_message)
    
    dialog_node_2d.set_dialog_data(_intro_dialog_data, self)
    dialog_node_2d.connect("dialog_completed", _on_dialog_completed)

func _on_force_move_completed(entity: CharacterBody2D) -> void:
    if entity in _waiting_for_force_move:
        _waiting_for_force_move.erase(entity)
    
func _on_dialog_completed() -> void:
    dialog_node_2d.visible = false
    _state = Level1_State.Battle
    BattleManager.battle_manager_start_battle(battle_background, [PlayerBattleStats.PlayerType.P1, PlayerBattleStats.PlayerType.P2], [PlayerBattleStats.PlayerType.BirdBoss])

func _on_collide_with_enemy(enemy: CharacterBody2D) -> void:
    match _state:
        Level1_State.Dialog:
            return
        Level1_State.Battle:
            return          
        Level1_State.ForceMovingPlayers:
            return  
        Level1_State.Overworld:
            if enemy is BirdBossOverworld:
                _state = Level1_State.ForceMovingPlayers
                p1.force_move(p_1_dialog_position_bird_boss.global_position, 60)
                p2.force_move(p_2_dialog_position_bird_boss.global_position, 60)
                _waiting_for_force_move.clear()
                _waiting_for_force_move.push_back(p1)
                _waiting_for_force_move.push_back(p2)
                
func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var input_event_key : InputEventKey = event as InputEvent
        if input_event_key.pressed and not input_event_key.echo:
            if input_event_key.physical_keycode == KEY_S:
                dialog_node_2d.visible = false
                _state = Level1_State.Battle
                BattleManager.battle_manager_start_battle(battle_background, [PlayerBattleStats.PlayerType.P1, PlayerBattleStats.PlayerType.P2], [PlayerBattleStats.PlayerType.BirdBoss])
                                
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    if _state == Level1_State.ForceMovingPlayers:
        if _waiting_for_force_move.size() == 0:
            dialog_node_2d.visible = true
            dialog_node_2d.start_dialog_from_beginning()
            _state = Level1_State.Dialog
