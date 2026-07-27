class_name DialogNode2D
extends Node2D

enum DialogState { Inactive, RevealingText, PausedOnUser }
@onready var speech_text_label: RichTextLabel = %SpeechText
@export var chars_displayed_per_second: int

var _dialog_data: DialogData
var _state: DialogState
var _current_message_index: int
var _current_message_char_index: int
var _seconds_until_next_char: float
var _text_font: Font
var _font_size: int

var _lines_for_current_message: Array[String]
var _cur_line_index: int
var _cur_line_char_index: int

class MessageDisplayData:
    var number_of_lines_per_segment: int
    var message_segments: Array[MessageSegment]
    var cur_segment: int
    
class MessageSegment:
    var message: String
    var cur_character_index: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _state = DialogState.Inactive
    _text_font = speech_text_label.get_theme_font("normal_font")
    _font_size = speech_text_label.get_theme_font_size("normal_font_size")
    visible = false
 
func set_dialog_data(dialog_data: DialogData) -> void:
    _dialog_data = dialog_data 
    pass

func fill_words_from_message(cur_message: DialogData.DialogMessage) -> void:
    
    var message_text_with_space := cur_message.message_text + ' '
    _lines_for_current_message.clear()
    _cur_line_index = 0
    _cur_line_char_index = 0
    var cur_line_text := ""
    var cur_word := ""
    
    for character in message_text_with_space:
        if character == ' ' and cur_word.length() > 0:
            var text_with_new_word: String
            if cur_line_text.length() == 0:
                text_with_new_word = cur_word
            else:
                text_with_new_word = cur_line_text + ' ' + cur_word
                
            var pixel_len := _text_font.get_string_size(text_with_new_word, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
            if pixel_len.x > speech_text_label.size.x:
                _lines_for_current_message.push_back(cur_line_text)
                cur_line_text = cur_word
            else:
                cur_line_text = text_with_new_word
            
            cur_word = ""
        else:
            cur_word+= character
            
    if cur_line_text.length() > 0:
        _lines_for_current_message.push_back(cur_line_text)
    
func start_dialog_from_beginning() -> void:
    # Wait for layout, so I get the actual size of the UI elements.  1 frame delay isn't really a problem
    visible = true
    await get_tree().process_frame
    _state = DialogState.RevealingText
    _current_message_index = 0
    _current_message_char_index = 0
    _seconds_until_next_char = 1.0 / chars_displayed_per_second as float
    fill_words_from_message(_dialog_data.messages[_current_message_index])
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    
    match _state:
        DialogState.Inactive:
            return
    
        DialogState.PausedOnUser:
            if Input.is_action_just_pressed('DialogNext'):
                if _cur_line_index == _lines_for_current_message.size() - 1:
                    _state = DialogState.Inactive
                    print("DONE")
                else: 
                    _cur_line_index += 1
                    _cur_line_char_index = 0
                    speech_text_label.text = ""
                    _state = DialogState.RevealingText
            return
        
        DialogState.RevealingText:
            _seconds_until_next_char -= delta
            if _seconds_until_next_char <= 0:
                speech_text_label.text += _lines_for_current_message[_cur_line_index][_cur_line_char_index]
                
                if _lines_for_current_message[_cur_line_index].length() - 1 == _cur_line_char_index:
                    if _cur_line_index % 2 == 1 or _cur_line_index == _lines_for_current_message.size() - 1:
                        _state = DialogState.PausedOnUser
                    else:
                        _cur_line_index += 1
                        _cur_line_char_index = 0
                        speech_text_label.text += "\n"
                else:
                    _cur_line_char_index += 1
                    
                _seconds_until_next_char = 1.0 / chars_displayed_per_second as float
