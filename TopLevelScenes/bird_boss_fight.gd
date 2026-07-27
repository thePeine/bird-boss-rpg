class_name BirdBossFight
extends Node2D

enum BossFightState { Idle, IntroDialog, Battle }
@onready var dialog_node: DialogNode2D = $Dialog

var _state: BossFightState
var _intro_dialog_data: DialogData


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _state = BossFightState.Idle
    _intro_dialog_data = DialogData.new()
    dialog_node.visible = false
    
    var path := "res://DataFiles/PreBossFightDialog.json"
    if not FileAccess.file_exists(path):
       push_error("Coudln't load lineup from disk")
       return
    
    var parsed_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    if parsed_data is Dictionary:
        var raw_messages: Variant = parsed_data.get("messages")
        if raw_messages is Array:
            var parsed_messages: Array = raw_messages
            for message: Dictionary in parsed_messages:
                var dialog_message := DialogData.DialogMessage.new()
                dialog_message.owner_name = message["owner_name"]
                dialog_message.message_text = message["message_text"]
                _intro_dialog_data.messages.push_back(dialog_message)
    
    dialog_node.set_dialog_data(_intro_dialog_data, self)
    dialog_node.connect("dialog_completed", _on_dialog_completed)

func _on_dialog_completed() -> void:
    dialog_node.visible = false
    _state = BossFightState.Battle
    
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    match _state:
        BossFightState.Idle:
            var should_start_dialog := Input.is_action_just_pressed('StartDialog')    
            if should_start_dialog:
                dialog_node.visible = true
                dialog_node.start_dialog_from_beginning()
                _state = BossFightState.IntroDialog
        BossFightState.IntroDialog:
            return
        BossFightState.Battle:
            return
    pass
