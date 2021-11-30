extends Node

const STATUS_ROUTE = "/cluster/status"

var _http_client  = HTTPRequest.new()
var _timer: Timer = Timer.new()

onready var _journal: Journal = get_node("VBoxContainer/VSplitContainer/Journal")
onready var _connected_icon: Button = get_node("VBoxContainer/Toolbar/ConnectedIcon")
onready var _url: Label = get_node("VBoxContainer/Toolbar/URL")
onready var _cluster_status_label: Label = get_node("VBoxContainer/Toolbar/ClusterStatus")
onready var _iteration: Label = get_node("VBoxContainer/Toolbar/Iteration")
onready var _population: Label = get_node("VBoxContainer/Toolbar/Population")
onready var _mode: Label = get_node("VBoxContainer/Toolbar/Mode")
onready var _master_node: Button = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Tabs/Cluster/MasterNode")
onready var _workers_grid: GridContainer = get_node("VBoxContainer/VSplitContainer/HBoxContainer/Tabs/Cluster/Workers")

const Worker = preload("res://Worker.gd")

var _cluster_status: String = ""
var _cluster_hash           = -1
var _workers: Dictionary    = {}


func _ready():
    _http_client.connect("request_completed", self, "_on_cluster_status_received")
    _timer.connect("timeout", self, "_request_status")
    _timer.set_wait_time(2)

    add_child(_timer)
    add_child(_http_client)


func _on_cluster_status_received(result, response_code, headers, body):
    if response_code != 200:
        _timer.stop()
        _connected_icon.set_offline()
        _master_node.change_status(_master_node.Master_Status.UNKNOWN)
        _journal.record("Connection error: status - %d" % response_code)
    else:
        _connected_icon.set_online()
        _master_node.change_status(_master_node.Master_Status.CONNECTED)
#        _journal.record("Received cluster status")
        var json = JSON.parse(body.get_string_from_utf8()).result

        var status = json["status"]
        var cluster_hash = int(json["hash"])
        _cluster_status = status
        match status:
            "Idle":
                if cluster_hash != _cluster_hash:
                    var workers = json["workersRaw"]
                    for worker in workers:
                        _workers[worker["actor"]] = {"capabilities": worker["capabilities"]}
                    _refresh_grid()
            "Running":
                var mode = json["mode"]
                var iteration = int(json["iteration"])
                var population = int(json["population"])
                _iteration.set_iteration(iteration)
                _population.set_population(population)
                _mode.set_mode(mode)
                if cluster_hash != _cluster_hash:
                    var workers = json["workers"]
                    for worker in workers:
                        var info = {}
                        info["capabilities"] = worker["capabilities"]
                        info["active"] = bool(worker["active"])
                        info["neighbors"] = worker["neighbors"]
                        _workers[worker["ref"]] = info
                    _refresh_grid()

        _cluster_hash = cluster_hash


func _refresh_grid() -> void:
    _cluster_status_label.change_cluster_status(_cluster_status)
    for child in _workers_grid.get_children():
        child.free()
    match _cluster_status:
        "Idle":
            for id in _workers:
                var worker_node = Worker.new(id, _workers[id])
                worker_node.change_status(worker_node.WorkerStatus.IDLE)
                _workers_grid.add_child(worker_node)
        "Running":
            for id in _workers:
                var worker_node = Worker.new(id, _workers[id])
                if _workers[id]["active"]:
                    worker_node.change_status(worker_node.WorkerStatus.ACTIVE)
                else:
                    worker_node.change_status(worker_node.WorkerStatus.IDLE)
                _workers_grid.add_child(worker_node)


func _request_status() -> void:
    var err = _http_client.request(_url.text + STATUS_ROUTE)
    if err != OK:
        _journal.record("Cluster status request faulure: %s" % err)


func _on_connect_command(hostname, port) -> void:
    _url.text = "http://%s:%s" % [hostname, port]
    _timer.start()
