extends TextEdit

class_name Journal

const _format  = "%s - %s\n"
const _error_format = "%s - ERROR: %s\n"
const _iso8601 = "%d-%02d-%02dT%02d:%02d:%02d"

export var in_UTC  = false

var _counter = 0

func record(note: String) -> void:
    _counter += 1
    text += _format % [_timestamp(), note]
    cursor_set_line(_counter)


func error(note: String) -> void:
    _counter += 1
    text += _error_format % [_timestamp(), note]
    cursor_set_line(_counter)


func _timestamp() -> String:
    var dt = OS.get_datetime(in_UTC)
    return _iso8601 % [dt['year'], dt['month'], dt['day'], dt['hour'], dt['minute'], dt['second']]
