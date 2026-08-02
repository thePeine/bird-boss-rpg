class_name PlayerCharacterP2
extends CharacterBody2D


enum PlayerCharacterState { Idle, InDialog, ForcedMove}
var _state: PlayerCharacterState

const SPEED = 300.0

signal force_move_completed(entity: CharacterBody2D)

@export var leader_character: CharacterBody2D
@export var _num_steps_behind: int

var _steps_to_follow: Array[Vector2]
var _next_step_index: int
var _leader_last_position: Vector2

var forced_move_global_location: Vector2 = Vector2(0,0)
var force_move_speed: float = SPEED

func force_move(location: Vector2, speed: float) -> void:
    forced_move_global_location = location
    _state = PlayerCharacterState.ForcedMove
    force_move_speed = speed
    
func _ready() -> void:
    _state = PlayerCharacterState.Idle
    
    if not leader_character:
        push_error("You have to set a character that is leading P2")
        return
        
    _leader_last_position = leader_character.global_position
    var _distace_from_following: = global_position - leader_character.global_position
    
    _steps_to_follow.resize(_num_steps_behind)
    
    var step_multilier: float = (1 as float) / (_num_steps_behind as float) as float
    for i in range(_num_steps_behind):
        _steps_to_follow[i] = -_distace_from_following * step_multilier
    
    _next_step_index = 0
    
func _physics_process(delta: float) -> void:
    if _state == PlayerCharacterState.Idle:
        if not leader_character.global_position == _leader_last_position:
            position += _steps_to_follow[_next_step_index]
            _steps_to_follow[_next_step_index] = leader_character.global_position - _leader_last_position
            _next_step_index = posmod(_next_step_index + 1, _steps_to_follow.size())
            _leader_last_position = leader_character.global_position
    if _state == PlayerCharacterState.ForcedMove:
        if not forced_move_global_location == global_position:
            var direction := forced_move_global_location - global_position
            var move_length := direction.length()
            if move_length < 2:
                global_position = forced_move_global_location                
            else:
                direction = direction.normalized()
                global_position += direction * force_move_speed * delta
            
            if global_position == forced_move_global_location:
                force_move_completed.emit(self)
        return
