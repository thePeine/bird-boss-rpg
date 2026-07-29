class_name DialogNode2D
extends Node2D

enum DialogState { Inactive, RevealingText, PausedOnUser }
@onready var speech_text_label: RichTextLabel = %SpeechText
@export var chars_displayed_per_second: int
@onready var speech_bubble_bottom: Marker2D = $SpeechBubbleBottom
@onready var speech_indicator: Polygon2D = $NinePatchRect/SpeechIndicator

signal dialog_completed()

var _dialog_data: DialogData
var _scene_search_root: Node2D

var _state: DialogState
var _current_message_index: int
var _seconds_until_next_char: float
var _text_font: Font
var _font_size: int

var _message_display_data: MessageDisplayData

var str_size_test: Vector2

var get_second_per_char: float:
    get:
        return 1.0 / chars_displayed_per_second as float
        
class MessageDisplayData:
    var number_of_lines_per_segment: int
    var message_segments: Array[String]
    var cur_segment_index: int
    var cur_char_in_segment: int
    
    
    func AddSegment(to_add: String) -> void:
        message_segments.push_back(to_add)
    func IsOnLastSegment() -> bool:
        return cur_segment_index == message_segments.size() - 1
    func MoveToNextSegment() -> void:
        if IsOnLastSegment():
            push_error("You're already on the last segment.  Can't go any further than that bub")
        else:
            cur_segment_index += 1
            cur_char_in_segment = 0
    func HasCharLeftOnCurSegment() -> bool:
        return cur_char_in_segment < message_segments[cur_segment_index].length()
    func GetCurChar() -> String:
        return message_segments[cur_segment_index][cur_char_in_segment]
    func AdvanceToNextCharOnSegment() -> void:
        if !HasCharLeftOnCurSegment():
            push_error("You're already on the last char.  Can't go any further than that bub")
        else:
            cur_char_in_segment+=1
    
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    _state = DialogState.Inactive
    _text_font = speech_text_label.get_theme_font("normal_font")
    _font_size = speech_text_label.get_theme_font_size("normal_font_size")
    
    # probably not necassary, just to be safe that the height is the same for all my chars
    str_size_test = _text_font.get_string_size("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#%&'()*+,-./:;<=>?@[^_{|}~", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
    visible = false
    _message_display_data = MessageDisplayData.new()
    
    if chars_displayed_per_second <= 0:
        chars_displayed_per_second = 12
 
func set_dialog_data(dialog_data: DialogData, scene_search_root: Node2D) -> void:
    _dialog_data = dialog_data 
    _scene_search_root = scene_search_root
    pass

func fill_words_from_message(cur_message: DialogData.DialogMessage) -> void:
    
    var speaker_root := _scene_search_root.find_child(cur_message.owner_name) as Node2D
    if not speaker_root:
        push_error("Couldn't find the entity the speech bubble is for.  It will just show up randomly")
    else:
        var speaker_marker2D := speaker_root.find_child("SpeechBubbleMarker2D") as Marker2D
        if not speaker_marker2D:
            push_error("Couldn't find the a SpeechBubbleMarker2D to place the speech bubble.  It will just show up randomly")
        else:
            if speaker_marker2D.global_position.x < 180:
                global_position.x = 10
            else:
                global_position.x = 100
 
            # THIS won't work if the speaker is at the very top of the screen (The bubblue will show up out of view).
            # It also won't work if the User's X coordinat is too high / too low.
            # Will revisit that later                                   
            position.y = speaker_marker2D.global_position.y - speech_bubble_bottom.position.y
            speech_indicator.position.x = speaker_marker2D.global_position.x - global_position.x - 15
            
            
    speech_text_label.text = ""
    var speech_label_size := speech_text_label.size
    _message_display_data.message_segments.clear()
    _message_display_data.cur_segment_index = 0
    _message_display_data.cur_char_in_segment = 0
    _message_display_data.number_of_lines_per_segment = speech_label_size.y / str_size_test.y
    
    var message_text_with_space := cur_message.message_text + ' '
    
    var cur_line_text := ""
    var cur_segment_string := ""
    var cur_word := ""
    var lines_used_in_segment := 0
    
    for character in message_text_with_space:
        if character == ' ' and cur_word.length() > 0:
            var text_with_new_word: String
            if cur_line_text.length() == 0:
                text_with_new_word = cur_word
            else:
                text_with_new_word = cur_line_text + ' ' + cur_word
                
            var pixel_len := _text_font.get_string_size(text_with_new_word, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size)
            if pixel_len.x > speech_label_size.x:
                if lines_used_in_segment < _message_display_data.number_of_lines_per_segment - 1:
                    cur_segment_string += cur_line_text.trim_prefix(" ") + "\n"
                    lines_used_in_segment += 1
                else:
                    _message_display_data.AddSegment(cur_segment_string + cur_line_text)
                    lines_used_in_segment = 0
                    cur_segment_string = ""
                    
                cur_line_text = cur_word
            else:
                cur_line_text = text_with_new_word
            
            cur_word = ""
        else:
            cur_word+= character
            
    if cur_segment_string.length() > 0 or cur_line_text.length() > 0:
         _message_display_data.AddSegment(cur_segment_string + cur_line_text)
    
func start_dialog_from_beginning() -> void:
    # Wait for layout, so I get the actual size of the UI elements.  1 frame delay isn't really a problem
    await get_tree().process_frame
    _state = DialogState.RevealingText
    _current_message_index = 0
    _seconds_until_next_char = get_second_per_char
    fill_words_from_message(_dialog_data.messages[_current_message_index])
    pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
    match _state:
        DialogState.Inactive:
            return
    
        DialogState.PausedOnUser:
            if Input.is_action_just_pressed('DialogNext'):
                if _message_display_data.IsOnLastSegment():
                    if _current_message_index < _dialog_data.messages.size() - 1 :
                        _current_message_index += 1
                        fill_words_from_message(_dialog_data.messages[_current_message_index])
                        _state = DialogState.RevealingText
                    else:
                        _state = DialogState.Inactive
                        emit_signal("dialog_completed")
                else:
                    _message_display_data.MoveToNextSegment()
                    _state = DialogState.RevealingText
                    _seconds_until_next_char = get_second_per_char
                    speech_text_label.text = ""
            return
        
        DialogState.RevealingText:
             if Input.is_action_just_pressed('DialogNext'):
                speech_text_label.text =  _message_display_data.message_segments[_message_display_data.cur_segment_index]
                _state = DialogState.PausedOnUser
             else:
                _seconds_until_next_char -= delta
                if _seconds_until_next_char <= 0:
                    if _message_display_data.HasCharLeftOnCurSegment():
                        speech_text_label.text += _message_display_data.GetCurChar()
                        _message_display_data.AdvanceToNextCharOnSegment()
                    else:
                        _state = DialogState.PausedOnUser
                    _seconds_until_next_char = get_second_per_char
