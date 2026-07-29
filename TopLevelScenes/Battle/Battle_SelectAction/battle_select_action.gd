class_name battle_select_action
extends Node2D

var item_nodes: Array[ColorRect] 
var current_selected_item_index: int

@export var radius_x: float = 65.0     # Width of the wheel
@export var radius_z: float = 65.0     # Real depth of the wheel
@export var font: Font

# Rotate my circle so that the 1st entry is always in the front (By default, the first entry is on the Right)
const angle_adjust : float = PI / 2
signal on_action_selected(action_name: String)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    visible = false

func set_actions(in_action_names: Array[String]) -> void:
    for  action_name in in_action_names:
        
        var label: Label = Label.new()
        label.text = action_name
        label.add_theme_font_override("font", font)
        label.add_theme_font_size_override("font_size", 8)
        label.set_anchors_preset(Control.PRESET_FULL_RECT)
    
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    
        var color_rect: ColorRect = ColorRect.new()
        color_rect.color = Color(0, 0, 1, 1)
        color_rect.size = Vector2(12,12)
        color_rect.add_child(label)
        
        add_child(color_rect)
        item_nodes.push_back(color_rect)

func set_visibility(new_visibliity: bool) -> void:
    visible = new_visibliity
    if visible:
        current_selected_item_index = 0
        update_wheel()

func check_input() -> void:
    var right := Input.is_action_just_pressed('ui_right')
    var left := Input.is_action_just_pressed('ui_left')
    
    if right:
        current_selected_item_index = posmod(current_selected_item_index + 1, item_nodes.size())
        update_wheel()
    elif left:
        current_selected_item_index = posmod(current_selected_item_index - 1, item_nodes.size())
        update_wheel()
    
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    if visible:
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
        item.position = Vector2(screen_x, screen_y) - (item.size / 2.0).round()
        item.z_index = int(z_factor * 100)
        
        if i == current_selected_item_index:
            item.modulate.a = 1
        else:
            item.modulate.a = .4
