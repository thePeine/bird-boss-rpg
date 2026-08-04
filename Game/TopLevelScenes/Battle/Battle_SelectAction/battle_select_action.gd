class_name battle_select_action 
extends Node2D

var item_nodes: Array[TextureRect] = []
var actions: Array[BattleAttackData] = []
var current_selected_item_index: int = 0

@export var radius_x: float = 65.0 
@export var radius_z: float = 65.0 
@export var font: Font 

const angle_adjust: float = PI / 2
var _current_resolver: Callable

func _ready() -> void:
    visible = false
    set_process(false)


func fill_with_actions(in_actions: Array[BattleAttackData]) -> void:
    actions = in_actions
    current_selected_item_index = 0
    
    # Clear previous instances
    for child in get_children():
        remove_child(child)
        child.queue_free()
    item_nodes.clear()
    
    for action in in_actions:
        var rect := TextureRect.new()
        rect.texture = action.selection_texture
        add_child(rect)
        item_nodes.push_back(rect)
        
    await get_tree().process_frame
    
func select_action(in_actions: Array[BattleAttackData]) -> BattleAttackData:
    fill_with_actions(in_actions)
    update_wheel()
    modulate.a = 1.0
    visible = true
    set_process(true) # Turn processing inputs on only while choosing
    
    # Await an internal custom signal confirming the player's final choice
    var choice: BattleAttackData = await self.action_confirmed
    
    set_process(false)
    return choice


signal action_confirmed(chosen_action: BattleAttackData)

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed('ui_right'):
        current_selected_item_index = posmod(current_selected_item_index + 1, item_nodes.size())
        update_wheel()
    elif Input.is_action_just_pressed('ui_left'):
        current_selected_item_index = posmod(current_selected_item_index - 1, item_nodes.size())
        update_wheel()
    elif Input.is_action_just_pressed('ui_accept'):
        set_process(false) # Lock input down immediately during transitions
        var tween := create_tween()
        tween.tween_property(self, "modulate:a", 0.0, 0.4)
        await tween.finished
        visible = false
        action_confirmed.emit(actions[current_selected_item_index])


func force_select(in_actions: Array[BattleAttackData], to_select_index: int) -> void:
    fill_with_actions(in_actions)
    update_wheel()
    visible = true
    modulate.a = 1.0

    if to_select_index == -1:
        push_error("Force-selected action index missing.")
        action_confirmed.emit(actions[current_selected_item_index])
        return

    await get_tree().create_timer(.5).timeout

    while current_selected_item_index != to_select_index:
        var direction := -1 if to_select_index < current_selected_item_index else 1
        current_selected_item_index = posmod(current_selected_item_index + direction, item_nodes.size())
        update_wheel()
        await get_tree().create_timer(.5).timeout
    
    set_process(false) # Lock input down immediately during transitions
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.4)
    await tween.finished
    visible = false
    action_confirmed.emit(actions[current_selected_item_index])


func update_wheel() -> void:
    var count := item_nodes.size()
    if count == 0: return
    
    for i in range(count):
        var index_from_order := posmod(current_selected_item_index - i, item_nodes.size())
        var angle := angle_adjust + (index_from_order * TAU / count)
        
        var x := cos(angle) * radius_x
        var z := sin(angle) * radius_z
        var z_factor := remap(z, -radius_z, radius_z, 0.4, 1.2)
        var screen_x := x * z_factor
        var screen_y := z * 0.4
        
        var item := item_nodes[i]
        item.position = Vector2(screen_x, screen_y) - (item.size / 2.0).round() + Vector2(0, -radius_z)
        item.z_index = int(z_factor * 100)
        item.modulate.a = 1.0 if i == current_selected_item_index else 0.4
