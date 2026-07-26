class_name Skill
extends Resource

@export var skill_id: int
@export var skill_name: String
@export var skill_type: String
@export var job_name: String
var power: int
var skill_effect: Array[Callable] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func execute(caster, target) -> void:
	for effect in skill_effect:
		effect.call(caster, target, self)

#공용 스킬
func base_damage(caster, target, skill):
	power = 0


#1차 직업 스킬



#2차 직업 스킬



#3차 직업 스킬
