extends CenterContainer

@onready var master_volume = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/MasterVolume
@onready var bgm_volume = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/BgmVolume
@onready var sfx_volume = $Control/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/SfxVolume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_pressed() -> void:
	hide()


func _on_master_slider_value_changed(value: float) -> void:
	var volume = int(value * 100)
	master_volume.text = str(volume)
	#TODO 바뀐 음량 출력과 메인에 시그널 보내기


func _on_bgm_slider_value_changed(value: float) -> void:
	var volume = int(value * 100)
	bgm_volume.text = str(volume)


func _on_sfx_slider_value_changed(value: float) -> void:
	var volume = int(value * 100)
	sfx_volume.text = str(volume)
