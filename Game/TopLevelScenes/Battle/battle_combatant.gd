@abstract
class_name Combatant
extends CharacterBody2D


signal turn_completed(action_data: Dictionary)
signal died(combatant: Combatant)
signal stats_updated(combatant: Combatant)

@abstract func your_turn_started() -> void
@abstract func execute_action(action: BattleAttackData, target: Combatant) -> void
@abstract func get_active_combatant_marker() -> Marker2D
@abstract func get_available_actions() -> Array[BattleAttackData]
@abstract func get_stats() -> PlayerBattleStats

var battle_scene: BattleScene

func get_hit_target_marker() -> Marker2D:
    return $HitTarget

func is_dead() -> bool:
    return get_stats().current_health <= 0
    
func take_damage(amount: int) -> Variant:
    var label := Label.new()
    label.text = str(amount)
    label.add_theme_font_override("font", GLOBAL_CONST.RESOURCES.PIXEL_FONT)
    label.add_theme_font_size_override("font_size", 8)
    label.set("theme_override_colors/font_color", Color.RED)
    
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
    label.global_position = get_hit_target_marker().global_position
    
    var tween := create_tween().set_parallel(true)
    tween.tween_property(label, "position", position + Vector2(0, -50), 0.8)
    tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)
    tween.tween_property(label, "scale", Vector2(0.2, 0.2), 0.6).set_delay(0.2)
    tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
    tween.chain().tween_callback(label.queue_free)
    
    get_tree().root.add_child(label)
    await tween.finished
    get_stats().current_health = max(0,  get_stats().current_health - amount)
    
    stats_updated.emit(self)
    if is_dead():
        died.emit(self)
    return null
