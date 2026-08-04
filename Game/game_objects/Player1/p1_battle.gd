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
    Color("e6c84c"),
    Color("ca3434")
])

var p2_palette := PackedColorArray([
    Color("384cc5"), 
    Color("233394"), 
    Color("23844c"),
    Color("2a9c5a"),
    Color("4545be")
])

var aim_tween: Tween

func take_damage(task_queue: AsyncTaskQueue, amount: int) -> void:
    super.take_damage(task_queue, amount)
    task_queue.add_task_ref("charecter_damage_anim")
    animated_sprite_2d.play("taking_damage")
    await animated_sprite_2d.animation_finished
    task_queue.release_task_ref("charecter_damage_anim")    
    if is_dead():
        modulate.a = .2
        rotate(-PI / 2)
        animated_sprite_2d.play("dead")
    else:
        animated_sprite_2d.play("idle")
        
func _ready() -> void:
    _state = State.WAITING
    aim_tween = create_tween().set_loops()
    aim_tween.tween_property(aimball, "position", aimball_end.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade out over 1 second
    aim_tween.tween_property(aimball, "position", aimball_start.position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT) # Fade in over 1 second
    
    if party_member_name == "p2":
        var shader_material: ShaderMaterial = animated_sprite_2d.material.duplicate()
        shader_material.set_shader_parameter("active_color_count", 10)
        shader_material.set_shader_parameter("before_colors", original_palette)
        shader_material.set_shader_parameter("after_colors", p2_palette)
        animated_sprite_2d.material = shader_material
        
    
func get_active_combatant_marker() -> Marker2D:
    return $ActiveCombatantMarker

func _input(event: InputEvent) -> void:
    if _state == State.EXECUTING_ACTION and _currently_executing_action.unique_name == PartyManager.player_punch_attack_name:
        if event.is_action_pressed("ui_accept"):
            aimball_executed.emit(10)
            
func execute_action(task_queue: AsyncTaskQueue, action: BattleAttackData, target: Combatant) -> void:
     if action.unique_name == PartyManager.player_punch_attack_name:
        _currently_executing_action = action
        _current_target_combatant = target
        await execute_simple_punch(task_queue, action)
     else:
        var does_nothing_label := SceneHelpers.create_default_label(Color.RED, 8, "Action Not Implemented Yet")
        does_nothing_label.global_position = get_hit_target_marker().global_position - Vector2(50, 20)
        get_tree().root.add_child(does_nothing_label)
        await get_tree().create_timer(1.5).timeout
        does_nothing_label.queue_free()
    
func get_available_actions() -> Array[BattleAttackData]:
     return PartyManager.get_party_member(party_member_name).battle_attacks

func execute_simple_punch(task_queue: AsyncTaskQueue, action: BattleAttackData) -> void:
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
    var damage_multiplier : float = 1.0
    var pixels_from_perfect := (aimball.position - ((aimball_end.position + aimball_start.position)/2)).length()
    if pixels_from_perfect <= 5:
        aim_text.play("excellent")
        damage_multiplier = 1.4
    elif pixels_from_perfect <= 15:
        aim_text.play("great")
        damage_multiplier = 1.2
    else:
        aim_text.play("good")
        
    await aim_text.animation_finished
    aim_text.play("default")
    aim_text.visible = false
    
    aimer.visible = false
    animated_sprite_2d.play("charged_punch")
    battle_scene.deal_damage_to_combatant(_current_target_combatant, action.base_damage * damage_multiplier, task_queue)
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.position.y -= 74
    animated_sprite_2d.play("teleport_up")
    await animated_sprite_2d.animation_finished
    global_position = start_location
    animated_sprite_2d.play("teleport_down")
    await animated_sprite_2d.animation_finished
    animated_sprite_2d.position.y += 74
    animated_sprite_2d.play("idle")
    if not task_queue.is_finished():
        await task_queue.all_completed

    _state = State.WAITING

func your_turn_started(task_queue: AsyncTaskQueue) -> void:
    _state = State.WAITING

func get_stats() -> PlayerBattleStats:
    return PartyManager.get_party_member(party_member_name)

func request_turn_action(task_queue: AsyncTaskQueue) -> Combatant.BattleTurnResult:
    # Display the selection UI, and wait for the user to select an action.  When they select it, return it back to the battle_scene
    
    var select_action_ui := battle_scene.battle_select_action_scene
    var chosen_action: BattleAttackData = await select_action_ui.select_action(get_available_actions())
    
    battle_scene.enter_target_selection(self)
    var chosen_target: Combatant = await battle_scene.get_user_target_selection(self)
    
    return Combatant.BattleTurnResult.new(chosen_action, chosen_target)
