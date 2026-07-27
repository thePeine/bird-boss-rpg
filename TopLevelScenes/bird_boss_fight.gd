class_name BirdBossFight
extends Node2D

enum BossFightState { Idle, IntroDialog }
@onready var dialog_node: DialogNode2D = $Dialog

var _state: BossFightState
var _intro_dialog_data: DialogData


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _state = BossFightState.Idle
    _intro_dialog_data = DialogData.new()
    
    var first_dialog_message := DialogData.DialogMessage.new()
    first_dialog_message.owner_name = "P1"
    first_dialog_message.message_text = "Yup.  That's the one, Sugar.  We can't let him get away!"
    _intro_dialog_data.messages.push_back(first_dialog_message)
    
    dialog_node.set_dialog_data(_intro_dialog_data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    var should_start_dialog := Input.is_action_just_pressed('StartDialog')    
    if should_start_dialog:
        dialog_node.start_dialog_from_beginning()
    pass
