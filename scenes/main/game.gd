extends Control

const RECRUIT_WINDOW := preload("res://scenes/windows/recruit_window.tscn")
const HUNTER_WINDOW := preload("res://scenes/windows/hunter_window.tscn")
const TEAM_WINDOW := preload("res://scenes/windows/team_window.tscn")
const BATTLE_WINDOW := preload("res://scenes/windows/battle_window.tscn")
const BUILD_WINDOW := preload("res://scenes/windows/build_window.tscn")
const ITEM_WINDOW := preload("res://scenes/windows/item_window.tscn")
const RESEARCH_WINDOW := preload("res://scenes/windows/research_window.tscn")

@onready var controller_content: Container = $VBoxContainer/HBoxContainer/Controller/ControllerBackground/MarginContainer/ControllerContent
@onready var recruit_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/RecruitButton
@onready var hunter_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/HunterButton
@onready var team_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/TeamButton
@onready var battle_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/BattleButton
@onready var build_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/BuildButton
@onready var item_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/ItemButton
@onready var research_button: Button = $VBoxContainer/LowBar/MarginContainer/HBoxContainer2/ResearchButton

var _current_button: Button


func _ready() -> void:
	_select(recruit_button, RECRUIT_WINDOW)


func _select(button: Button, scene: PackedScene) -> void:
	if button == _current_button:
		return
	if _current_button:
		_current_button.disabled = false
	button.disabled = true
	_current_button = button
	_set_controller_content(scene)


func _set_controller_content(scene: PackedScene) -> void:
	for child in controller_content.get_children():
		child.queue_free()
	controller_content.add_child(scene.instantiate())


func _on_recruit_button_pressed() -> void:
	_select(recruit_button, RECRUIT_WINDOW)


func _on_hunter_button_pressed() -> void:
	_select(hunter_button, HUNTER_WINDOW)


func _on_team_button_pressed() -> void:
	_select(team_button, TEAM_WINDOW)


func _on_battle_button_pressed() -> void:
	_select(battle_button, BATTLE_WINDOW)


func _on_build_button_pressed() -> void:
	_select(build_button, BUILD_WINDOW)


func _on_item_button_pressed() -> void:
	_select(item_button, ITEM_WINDOW)


func _on_research_button_pressed() -> void:
	_select(research_button, RESEARCH_WINDOW)
