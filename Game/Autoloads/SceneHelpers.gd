class_name SceneHelpers
extends Node

static func create_default_label(font_color: Color, font_size: int, lable_text: String) -> Label:
    var ret := Label.new()
    ret.add_theme_font_override("font", GLOBAL_CONST.RESOURCES.PIXEL_FONT)
    ret.add_theme_font_size_override("font_size", font_size)
    ret.set("theme_override_colors/font_color", font_color)        
    ret.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ret.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    ret.text = lable_text
    return ret
