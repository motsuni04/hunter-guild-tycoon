extends Control

const CREDIT = preload("res://credit.tscn")

@onready var setting = $MarginContainer/Setting

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_button_3_pressed() -> void:
	setting.show()

func _on_button_4_pressed() -> void:
	var credit = CREDIT.instantiate()
	add_child(credit)
