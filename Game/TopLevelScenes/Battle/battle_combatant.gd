@abstract
class_name Combatant
extends CharacterBody2D


signal turn_completed(action_data: Dictionary)
signal died

@abstract func your_turn_started(battle_scene: BattleScene) -> void
@abstract func execute_action(action: BattleAttackData, target: Combatant) -> void
@abstract func get_active_combatant_marker() -> Marker2D
@abstract func get_available_actions() -> Array[BattleAttackData]

@abstract func is_dead() -> bool

func get_hit_target_marker() -> Marker2D:
    return $HitTarget

func take_damage(amount: int) -> void:
    var label := Label.new()
    label.text = str(amount)
    label.add_theme_font_override("font", GLOBAL_CONST.RESOURCES.PIXEL_FONT)
    label.add_theme_font_size_override("font_size", 8)
    label.set("theme_override_colors/font_color", Color.RED)
    
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    label.global_position = get_hit_target_marker().global_position
    
    var pivot_offset := label.size / 2
    var tween := create_tween().set_parallel(true)
    tween.tween_property(label, "position", position + Vector2(0, -50), 0.8)
    tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)
    tween.tween_property(label, "scale", Vector2(0.2, 0.2), 0.6).set_delay(0.2)
    tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
    tween.chain().tween_callback(label.queue_free)
    
    get_tree().root.add_child(label)
    
    print("Damage")
