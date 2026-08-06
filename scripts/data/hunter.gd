class_name Hunter
extends Resource

## 길드에 소속된 헌터 한 명의 데이터.
## 전투 능력치뿐 아니라 월급·스트레스처럼 "헌터 개인에게 붙는 값"은 전부 여기에 둔다.
## 반대로 "언제 월급을 주는가", "스트레스가 쌓이면 무슨 일이 생기는가" 같은 규칙은
## 헌터 한 명만 봐서는 결정할 수 없으므로 Guild / GameState 쪽이 담당한다.

## 레벨은 UI에 노출하지 않고, 등급이 오를 때만 알린다.
signal grade_changed(grade: Grade)
signal burned_out()

enum Grade { D, C, B, A, S, SS, SSS }

const GRADE_NAMES: Array[String] = ["D", "C", "B", "A", "S", "SS", "SSS"]
const MAX_LEVEL := 30
## 각 등급에 도달하는 최소 레벨. Grade 순서와 1:1로 대응한다.
## D만 1레벨에서 시작하고 이후로는 5레벨마다 한 등급씩,
## 마지막 SSS는 만렙(MAX_LEVEL)에 도달해야만 얻는다.
const GRADE_LEVELS: Array[int] = [1, 5, 10, 15, 20, 25, MAX_LEVEL]
## 등급별 기본 월급(만원). salary가 0일 때 이 값을 쓴다.
const GRADE_SALARIES: Array[int] = [30, 60, 120, 250, 500, 900, 1500]

## 레벨업에 필요한 경험치 = BASE_EXPERIENCE * EXPERIENCE_GROWTH ^ (레벨 - 1).
## 만렙이 낮은 대신 뒤로 갈수록 가파르게 오른다.
const BASE_EXPERIENCE := 100
const EXPERIENCE_GROWTH := 1.25

const MAX_STRESS := 100
## 레벨업 1회당 상승하는 능력치.
const GROWTH := {"health": 10, "strength": 2, "agility": 2, "mana": 2}

@export var hunter_id: int = 0
@export var hunter_name: String = "이름 없음"
@export var job_name: String = "무직"

## 레벨은 내부 수치라 화면에 직접 띄우지 않는다. 등급(grade)만 노출한다.
@export var level: int = 1
@export var experience: int = 0

@export_group("능력치")
## 체력. 그대로 최대 HP가 된다.
@export var health: int = 100
## 근력. 물리 공격력.
@export var strength: int = 10
## 민첩. 행동 순서와 회피.
@export var agility: int = 10
## 마력. 마법 공격력.
@export var mana: int = 10

@export_group("길드 운영")
## 월 지급액(만원). 0이면 등급 기본값(GRADE_SALARIES)을 따른다.
@export var salary: int = 0
@export_range(0, MAX_STRESS) var stress: int = 0

@export_group("스킬")
@export var skills: Array[Skill] = []

## 전투 중에만 쓰는 값이라 저장하지 않는다. 전투 시작 시 reset_for_battle()로 채운다.
var current_hp: int = 0

## 등급은 저장하지 않는다. 레벨에서 파생되는 값이라 항상 레벨이 원본이다.
var grade: Grade:
	get: return grade_for_level(level)


## 지정한 등급에 갓 도달한 헌터를 만든다. 인재 모집에서 쓴다.
static func create(new_name: String, new_job: String, new_grade: Grade) -> Hunter:
	var hunter := Hunter.new()
	hunter.hunter_name = new_name
	hunter.job_name = new_job
	hunter.level = min_level_for_grade(new_grade)
	hunter._apply_growth(hunter.level - 1)
	return hunter


#등급
static func grade_for_level(target_level: int) -> Grade:
	var result := Grade.D
	for i in GRADE_LEVELS.size():
		if target_level >= GRADE_LEVELS[i]:
			result = i as Grade
	return result


static func min_level_for_grade(target_grade: Grade) -> int:
	return GRADE_LEVELS[target_grade]


func grade_text() -> String:
	return GRADE_NAMES[grade] + "등급"


## 다음 등급까지의 진척도(0.0~1.0). 레벨 대신 이걸 게이지로 보여주면 된다.
func grade_progress() -> float:
	var current := grade
	if current == Grade.SSS:
		return 1.0
	var from := GRADE_LEVELS[current]
	var to := GRADE_LEVELS[current + 1]
	return float(level - from) / float(to - from)


#전투
func max_hp() -> int:
	return health


func reset_for_battle() -> void:
	current_hp = max_hp()


func is_alive() -> bool:
	return current_hp > 0


## Skill.base_damage 등에서 호출한다. 경감은 스킬/전투 쪽에서 계산해 넘긴다.
func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - maxi(0, amount), 0, max_hp())


func heal(amount: int) -> void:
	current_hp = clampi(current_hp + maxi(0, amount), 0, max_hp())


func physical_power() -> int:
	return strength


func magical_power() -> int:
	return mana


#성장
## 현재 레벨에서 다음 레벨로 가는 데 필요한 경험치.
func required_experience() -> int:
	return experience_for_level(level)


static func experience_for_level(target_level: int) -> int:
	return int(BASE_EXPERIENCE * pow(EXPERIENCE_GROWTH, target_level - 1))


## 레벨업이 일어났으면 true. 등급이 바뀌면 grade_changed를 함께 발생시킨다.
func gain_experience(amount: int) -> bool:
	if amount <= 0 or level >= MAX_LEVEL:
		return false
	var previous_grade := grade
	experience += amount
	var leveled_up := false
	while level < MAX_LEVEL and experience >= required_experience():
		experience -= required_experience()
		level += 1
		_apply_growth(1)
		leveled_up = true
	if level >= MAX_LEVEL:
		experience = 0
	if grade != previous_grade:
		grade_changed.emit(grade)
	return leveled_up


func _apply_growth(times: int) -> void:
	if times <= 0:
		return
	health += GROWTH.health * times
	strength += GROWTH.strength * times
	agility += GROWTH.agility * times
	mana += GROWTH.mana * times


#길드 운영
func monthly_salary() -> int:
	return salary if salary > 0 else GRADE_SALARIES[grade]


func is_burnout() -> bool:
	return stress >= MAX_STRESS


func stress_ratio() -> float:
	return float(stress) / float(MAX_STRESS)


## 번아웃에 새로 도달했으면 burned_out을 발생시킨다.
func add_stress(amount: int) -> void:
	if amount <= 0 or is_burnout():
		return
	stress = mini(MAX_STRESS, stress + amount)
	if is_burnout():
		burned_out.emit()


func relieve_stress(amount: int) -> void:
	stress = maxi(0, stress - maxi(0, amount))
