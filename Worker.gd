extends Button

class_name Worker

enum WorkerStatus {UNKNOWN, IDLE, ACTIVE}

var _status = WorkerStatus.UNKNOWN
var _style = load("res://WorkerStyle.tres")

func _init(id: String, capabilities: Dictionary) -> void:
    disabled = true
    focus_mode = Control.FOCUS_NONE
    text = id
    hint_tooltip = _form_worker_tooltip(capabilities)
    rect_min_size = Vector2(150, 70)
    add_color_override("font_color_disabled", Color.black)
    add_stylebox_override("disabled", _style.duplicate())


func change_status(to) -> void:
    _status = to
    match to:
        WorkerStatus.UNKNOWN:
            self["custom_styles/disabled"].bg_color = Color.gray
        WorkerStatus.IDLE:
            self["custom_styles/disabled"].bg_color = Color.beige
        WorkerStatus.ACTIVE:
            self["custom_styles/disabled"].bg_color = Color.forestgreen


func _form_worker_tooltip(info: Dictionary) -> String:
    var tip = ""
    for key in info:
        var value = info[key]
        if value is Dictionary:
            tip += "%s:\n  %s" % [key, _form_worker_tooltip(value)]
        else:
            tip += "%s: %s\n" % [key, value]
    return tip
