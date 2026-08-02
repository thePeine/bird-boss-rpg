class_name battle_select_action
extends Node2D

var item_nodes: Array[TextureRect] 
var actions: Array[BattleAttackData]
var current_selected_item_index: int

@export var radius_x: float = 65.0     # Width of the wheel
@export var radius_z: float = 65.0     # Real depth of the wheel
@export var font: Font

# Rotate my circle so that the 1st entry is always in the front (By default, the first entry is on the Right)
const angle_adjust : float = PI / 2
signal on_action_selected(action: BattleAttackData)

var enabled: bool
var is_automated: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    visible = false
    enabled = false

func get_current_selected_item() -> BattleAttackData:
    return actions[current_selected_item_index]
    
func set_actions(in_actions: Array[BattleAttackData], in_is_automated: bool) -> void:
    is_automated = in_is_automated
    actions = in_actions
    item_nodes.clear()
    for child in get_children():
        child.queue_free()
        
    for  action in in_actions:
        
        var action_texture_rect: TextureRect = TextureRect.new()
        action_texture_rect.texture = action.selection_texture
        add_child(action_texture_rect)
        item_nodes.push_back(action_texture_rect)

    update_wheel()
    
func set_visibility(new_visibliity: bool) -> void:
    visible = new_visibliity
    if visible:
        current_selected_item_index = 0
        enabled = true
        update_wheel()
        modulate.a = 1

func force_select(to_select: BattleAttackData) -> void:
    
    var index_to_select := actions.find(to_select)
    if index_to_select == -1:
        push_error("called force_select on an action that didn't exist on that player....just skip it")
        on_action_selected.emit(actions[current_selected_item_index])
    
    await get_tree().create_timer(0.5).timeout
    if not index_to_select == current_selected_item_index:
        var diff : int = abs(index_to_select - current_selected_item_index)
        var direction := -1 if index_to_select < current_selected_item_index else 1
        for i in range(diff):
            current_selected_item_index = posmod(current_selected_item_index + direction, item_nodes.size())
            update_wheel()
            await get_tree().create_timer(0.5).timeout
    
    visible = false
    enabled = false
    on_action_selected.emit(actions[current_selected_item_index])
    
func check_input() -> void:
    if Input.is_action_just_pressed('ui_right'):
        current_selected_item_index = posmod(current_selected_item_index + 1, item_nodes.size())
        update_wheel()
    elif Input.is_action_just_pressed('ui_left'):
        current_selected_item_index = posmod(current_selected_item_index - 1, item_nodes.size())
        update_wheel()
    elif Input.is_action_just_pressed('ui_accept'):
        var tween := create_tween()
        enabled = false
        tween.tween_property(self, "modulate:a", 0.0, .4)
        tween.finished.connect(func() -> void: 
            visible = false
            on_action_selected.emit(actions[current_selected_item_index])
            modulate.a = 1
        )
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if enabled and visible and not is_automated:
        check_input()

func update_wheel() -> void:
    var count := item_nodes.size()
    
    for i in range(count):
        var index_from_order := posmod(current_selected_item_index - i, item_nodes.size())
        var angle := angle_adjust + (index_from_order * TAU / count)
        
        # Calculate where we are on our X/Z circle
        var x := cos(angle) * radius_x
        var z := sin(angle) * radius_z 
        
        var z_factor := remap(z, -radius_z, radius_z, 0.4, 1.2)
        var screen_x := x * z_factor
        var screen_y := z * 0.4 
        
        var item := item_nodes[i]
        item.position = Vector2(screen_x, screen_y) - (item.size / 2.0).round() + Vector2(0,-radius_z)
        item.z_index = int(z_factor * 100)
        
        if i == current_selected_item_index:
            item.modulate.a = 1
        else:
            item.modulate.a = .4
