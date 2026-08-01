extends Combatant

enum State { WAITING, EXECUTING_ACTION_ACTIVE,  EXECUTING_ACTION_PASSIVE, EXECUTING_ACTION_COMPLETE}
var _state: State
var _currently_executing_action: BattleAttackData
var _current_target_combatant: Combatant


@onready var animated_sprite_2d: AnimatedSprite2D = $FootOffset/AnimatedSprite2D
@onready var aimer: Node2D = $Aimer
@onready var aimball: Sprite2D = $Aimer/Aimball
@onready var aimball_end: Marker2D = $Aimer/AimballEnd
@onready var aimball_start: Marker2D = $Aimer/AimballStart

var aim_tween: Tween

func take_damage(amount: int) -> void:
    super.take_damage(amount)

func is_dead() -> bool:
    return false

func _ready() -> void:
    _state = State.WAITING
    print("aimball = " + str(aimball.global_position) + " start is " + str(aimball_start.global_position) + " end is " + str(aimball_end.global_position))
    aim_tween = create_tween().set_loops()
    aim_tween.tween_property(aimball, "position", aimball_end.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade out over 1 second
    aim_tween.tween_property(aimball, "position", aimball_start.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade in over 1 second
    pass
    
func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker
    
func _physics_process(delta: float) -> void:
    match _state:
        State.WAITING:
            return
        State.EXECUTING_ACTION_ACTIVE:
            # TODO(nick) - Move this out of the physcis method
            if Input.is_action_just_pressed('ui_accept'):
                #animated_sprite_2d.play("charged_punch")
                _state = State.EXECUTING_ACTION_PASSIVE
                
                var start_location := global_position
                var hit_target_location := _current_target_combatant.get_hit_target_marker().global_position
                hit_target_location.y += 20 #Temporary. This information should be part of the attack action, just hardcoding for now
                aim_tween.pause()
                var tween := create_tween()
                tween.tween_interval(0.5)
                tween.tween_callback(func() -> void:
                    aimer.visible = false
                )
                tween.tween_property(self, "global_position", hit_target_location, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tween.tween_callback(func() -> void: 
                    animated_sprite_2d.play("charged_punch")
                    _current_target_combatant.take_damage(5)
                )
                tween.tween_callback(func() -> void: 
                    await animated_sprite_2d.animation_finished 
                    print("DONE")
                )
                var frame_count := animated_sprite_2d.sprite_frames.get_frame_count("charged_punch")
                var FPS := animated_sprite_2d.sprite_frames.get_animation_speed("charged_punch")
                var duration := frame_count / FPS
                tween.tween_interval(duration)
                tween.tween_property(self, "global_position", start_location, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
                tween.tween_callback(func() -> void: 
                    animated_sprite_2d.play("idle")
                    _state = State.EXECUTING_ACTION_COMPLETE
                )
        State.EXECUTING_ACTION_PASSIVE:
            return
        State.EXECUTING_ACTION_COMPLETE:
            turn_completed.emit({})
            _state = State.WAITING
            return
            
    


func execute_action(action: BattleAttackData, target: Combatant) -> void:
     print("Executing action " + action.display_string + " on target " + target.name)
     if action == GS.KnownAttacks.get_attack("PlayerRegPunch"):
        animated_sprite_2d.play("charging_punch")
        _state = State.EXECUTING_ACTION_ACTIVE
        _currently_executing_action = action
        _current_target_combatant = target
        aimer.visible = true
        aim_tween.play()
    
func get_available_actions() -> Array[BattleAttackData]:
    return [GS.KnownAttacks.get_attack("PlayerRegPunch"), GS.KnownAttacks.get_attack("PlayerUseItem"), GS.KnownAttacks.get_attack("PlayerBroAttack")]
