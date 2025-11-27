extends Node

var api

func _ready() -> void:
	api = Metacom.create("ws://127.0.0.1:8000/api")

	const method = "market.2/getProducts"
	const args = {
		"page": 1,
		"listType": "APP",
	}
	var result = await api.send(method, args) 
	print("Start game", result)

func _process(_delta: float) -> void:
	api.poll()
	
