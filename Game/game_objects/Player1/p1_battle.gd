class_name p1_combatant 
extends Combatant

enum State { WAITING, EXECUTING_ACTION}
var _state: State
var _currently_executing_action: BattleAttackData
var _current_target_combatant: Combatant

signal aimball_executed

@onready var animated_sprite_2d: AnimatedSprite2D = $FootOffset/AnimatedSprite2D
@onready var aimer: Node2D = $Aimer
@onready var aimball: Sprite2D = $Aimer/Aimball
@onready var aimball_end: Marker2D = $Aimer/AimballEnd
@onready var aimball_start: Marker2D = $Aimer/AimballStart
@onready var aim_text: AnimatedSprite2D = $Aimer/AimText

@export var party_member_name: String

var original_palette := PackedColorArray([
    Color("bd3b3b"),
    Color("ac3232"),
    Color("ceb344"),
    Color("e6c84c")
])

var p2_palette := PackedColorArray([
    Color("384cc5"), 
    Color("233394"), 
    Color("23844c"),
    Color("2a9c5a")
])

var aim_tween: Tween

func take_damage(amount: int) -> void:
    super.take_damage(amount)

func is_dead() -> bool:
    return false

func _ready() -> void:
    _state = State.WAITING
    aim_tween = create_tween().set_loops()
    aim_tween.tween_property(aimball, "position", aimball_end.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade out over 1 second
    aim_tween.tween_property(aimball, "position", aimball_start.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade in over 1 second
    
    if party_member_name == "p2":
        var material: ShaderMaterial = animated_sprite_2d.material.duplicate()
        material.set_shader_parameter("active_color_count", 10)
        material.set_shader_parameter("before_colors", original_palette)
        material.set_shader_parameter("after_colors", p2_palette)
        animated_sprite_2d.material = material
    
func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker

func _input(event: InputEvent) -> void:
    if _state == State.EXECUTING_ACTION and _currently_executing_action.unique_name == PartyManager.player_punch_attack_name:
        if Input.is_action_just_pressed('ui_accept'):
            aimball_executed.emit(10)
            
func execute_action(action: BattleAttackData, target: Combatant) -> void:
     print("Executing action " + action.display_string + " on target " + target.name)
     if action.unique_name == PartyManager.player_punch_attack_name:
        _currently_executing_action = action
        _current_target_combatant = target
        execute_simple_punch()
    
func get_available_actions() -> Array[BattleAttackData]:
     return PartyManager.get_party_member(party_member_name).battle_attacks

func execute_simple_punch() -> void:
    _state = State.EXECUTING_ACTION
    var start_location := global_position
    
    animated_sprite_2d.position.y -= 74
    animated_sprite_2d.play("teleport_up")
    await animated_sprite_2d.animation_finished
    global_position = _current_target_combatant.get_hit_target_marker().global_position + Vector2(-20,20)
    animated_sprite_2d.play("teleport_down")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.play("charging_punch")
    animated_sprite_2d.position.y += 74    
    await animated_sprite_2d.animation_finished
    aimer.visible = true
    aim_tween.play()
    await aimball_executed
    aim_tween.pause()
    
    aim_text.visible = true
    var pixels_from_perfect := (aimball.position - ((aimball_end.position + aimball_start.position)/2)).length()
    if pixels_from_perfect <= 5:
        aim_text.play("excellent")
    elif pixels_from_perfect <= 15:
        aim_text.play("great")
    else:
        aim_text.play("good")
        
    await aim_text.animation_finished
    aim_text.play("default")
    aim_text.visible = false
    
    aimer.visible = false
    animated_sprite_2d.play("charged_punch")
    _current_target_combatant.take_damage(5)
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.position.y -= 74
    animated_sprite_2d.play("teleport_up")
    await animated_sprite_2d.animation_finished
    global_position = start_location
    animated_sprite_2d.play("teleport_down")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.position.y += 74
    animated_sprite_2d.play("idle")
    _state = State.WAITING
    turn_completed.emit({})

func your_turn_started(battle_scene: BattleScene) -> void:
    _state = State.WAITING
