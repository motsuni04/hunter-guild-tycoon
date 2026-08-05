class_name Hunter
extends Resource

## 길드에 소속된 헌터 한 명의 데이터.

enum Grade { F, E, D, C, B, A, S }

const GRADE_NAMES := ["F", "E", "D", "C", "B", "A", "S"]
const MAX_LEVEL := 99

@export var hunter_id: int = 0
@export var hunter_name: String = "이름 없음"
@export var job_name: String = "무직"
@export var grade: Grade = Grade.F
@export var level: int = 1
@export var experience: int = 0

@export_group("능력치")
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10

@export_group("스킬")
@export var skills: Array[Skill] = []

## 전투 중에만 쓰는 값이라 저장하지 않는다. 전투 시작 시 reset_for_battle()로 채운다.
var current_hp: int = 0


#표시용
func grade_text() -> String:
	return GRADE_NAMES[grade] + "등급"


func level_text() -> String:
	return "Lv.%d" % level


#전투
func reset_for_battle() -> void:
	current_hp = max_hp


func is_alive() -> bool:
	return current_hp > 0


## Skill.base_damage 등에서 호출한다. 방어력만큼 경감하되 최소 1은 들어간다.
func take_damage(amount: int) -> void:
	var reduced := maxi(1, amount - defense)
	current_hp = maxi(0, current_hp - reduced)


func heal(amount: int) -> void:
	current_hp = mini(max_hp, current_hp + amount)


#성장
func required_experience() -> int:
	return level * 100


## 레벨업이 일어났으면 true를 반환한다.
func gain_experience(amount: int) -> bool:
	if level >= MAX_LEVEL:
		return false
	experience += amount
	var leveled_up := false
	while level < MAX_LEVEL and experience >= required_experience():
		experience -= required_experience()
		_level_up()
		leveled_up = true
	if level >= MAX_LEVEL:
		experience = 0
	return leveled_up


func _level_up() -> void:
	level += 1
	max_hp += 10
	attack += 2
	defense += 1
	speed += 1
