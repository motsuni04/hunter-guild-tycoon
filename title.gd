extends Control

@onready var CreditContainer = $MarginContainer/CenterContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_4_pressed() -> void:
	CreditContainer.show()


func _on_exit_pressed() -> void:
	CreditContainer.hide()
