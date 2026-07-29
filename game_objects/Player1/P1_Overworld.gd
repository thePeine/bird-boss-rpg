class_name PlayerCharacter
extends CharacterBody2D

enum PlayerCharacterState { Idle, InDialog, ForcedMove}
var _state: PlayerCharacterState

signal collide_with_enemy(enemy: CharacterBody2D)
signal force_move_completed(entity: CharacterBody2D)

@export var SPEED: int = 200

var forced_move_global_location: Vector2 = Vector2(0,0)
var force_move_speed: float = SPEED

func force_move(location: Vector2, speed: float) -> void:
    forced_move_global_location = location
    _state = PlayerCharacterState.ForcedMove
    force_move_speed = speed
    
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _state = PlayerCharacterState.Idle

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
    if _state == PlayerCharacterState.InDialog:
        return
        
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
        
    var directionX := Input.get_axis("ui_left", "ui_right")
    if directionX:
        velocity.x = directionX * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
    
    var directionY := Input.get_axis("ui_up", "ui_down")
    if directionY:
        velocity.y = directionY * SPEED
    else:
        velocity.y = move_toward(velocity.y, 0, SPEED)
        
    move_and_slide()
    var num_collisions := get_slide_collision_count()
    if num_collisions > 0:
        for i in range(num_collisions):
            var collision := get_slide_collision(i)
            var collider := collision.get_collider()
            if collider is BirdBossOverworld:
                collide_with_enemy.emit(collider)
                return
