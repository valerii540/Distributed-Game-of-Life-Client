extends Node

var server = "localhost"

const ws_route     = "/events"
const status_route = "/cluster/status"

var _ws_client = WebSocketClient.new()
var _http_client = HTTPRequest.new()

onready var _journal: Journal = get_node("VBoxContainer/VSplitContainer/Journal")
onready var _connected_icon: Button = get_node("VBoxContainer/Toolbar/ConnectedIcon")


func _ready():
    add_child(_http_client)
    _ws_client.connect("connection_closed", self, "_closed")
    _ws_client.connect("connection_error", self, "_closed")
    _ws_client.connect("connection_established", self, "_connected")
    _ws_client.connect("data_received", self, "_on_data")


func _process(delta):
    _ws_client.poll()


func _connected(proto: String = "") -> void:
    _journal.record("Connection established with %s" % server)
    _connected_icon.set_online()

    _http_client.connect("request_completed", self, "_on_cluster_status_received")
    _http_client.request(server + status_route)


func _on_cluster_status_received(result, response_code, headers, body):
    var json = JSON.parse(body.get_string_from_utf8())
    print(json.result)
    _http_client.disconnect("request_completed", self, "_on_cluster_status_received")


func _on_connect_command(hostname, port) -> void:
    server = "http://%s:%s" % [hostname, port]
    var err = _ws_client.connect_to_url(server + ws_route)
    if err != OK:
        _journal.record("Connection error: %s" % err)


func _on_data():
    print("Got new data via WS: ", _ws_client.get_peer(1).get_packet().get_string_from_utf8())


func _closed(was_clean: bool = false) -> void:
    _connected_icon.set_offline()
    if was_clean:
        _journal.record("Gracefully disconected from cluster")
    else:
        _journal.record("Brutally disconected from cluster")
