extends TextEdit

class_name Journal

const _format  = "%s - %s\n"
const _iso8601 = "%d-%02d-%02dT%02d:%02d:%02d"
export var in_UTC  = false

func record(note: String) -> void:
    text += _format % [_timestamp(), note]

func _timestamp() -> String:
    var dt = OS.get_datetime(in_UTC)
    return _iso8601 % [dt['year'], dt['month'], dt['day'], dt['hour'], dt['minute'], dt['second']]
