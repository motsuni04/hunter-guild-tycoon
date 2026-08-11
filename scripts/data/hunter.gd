class_name Hunter
extends Resource

signal grade_changed(grade: Grade)
signal burned_out()

enum Grade { D, C, B, A, S, SS, SSS }
## 성자 성녀 구분용
enum Gender { MALE, FEMALE }

const GRADE_NAMES: Array[String] = ["D", "C", "B", "A", "S", "SS", "SSS"]
const MAX_LEVEL := 30
const GRADE_LEVELS: Array[int] = [1, 5, 10, 15, 20, 25, MAX_LEVEL]
## 임시 월급 기본값
const BASE_SALARIES: Array[int] = [40, 100, 200, 370, 620, 940, 1400]
const SALARY_MULTIPLIER_RANGE := Vector2(0.8, 1.2)

## 레벨업에 필요한 경험치 = BASE_EXPERIENCE * EXPERIENCE_GROWTH ^ (레벨 - 1).
const BASE_EXPERIENCE := 100
const EXPERIENCE_GROWTH := 1.15

const MAX_STRESS := 100

## D등급에 1차(기본), B등급에 2차, SS등급에 3차 직업으로 전직
const TIER_GRADES: Array[Grade] = [Grade.D, Grade.B, Grade.SS]

@export var hunter_id: int = 0
@export var hunter_name: String = "무명"
@export var hunter_gender: Gender = Gender.MALE

@export var job_line: String = "warrior"
@export var job_tier: int = Job.MIN_TIER

@export var level: int = 1
@export var experience: int = 0

@export_group("능력치")
@export var health: int = 100
@export var strength: int = 10
@export var agility: int = 10
@export var mana: int = 10

@export_group("길드 운영")
@export var salary: int = 0
@export var salary_multiplier: float = 1.0
@export_range(0, MAX_STRESS) var stress: int = 0

@export_group("스킬")
@export var skills: Array[Skill] = []

## 전투 중에만 쓰는 값이라 저장하지 않는다. 전투 시작 시 reset_for_battle()로 채운다.
var current_hp: int = 0

## 등급은 저장하지 않는다. 레벨에서 파생되는 값이라 항상 레벨이 원본이다.
var grade: Grade:
	get: return grade_for_level(level)


static func create(new_name: String, line: String, new_grade: Grade, multiplier: float = 0.0) -> Hunter:
	var hunter := Hunter.new()
	hunter.hunter_name = new_name
	hunter.job_line = line
	hunter.level = min_level_for_grade(new_grade)
	hunter.job_tier = tier_for_level(hunter.level)
	hunter._apply_growth(hunter.level - 1)
	hunter.salary_multiplier = multiplier if multiplier > 0.0 else randf_range(
		SALARY_MULTIPLIER_RANGE.x, SALARY_MULTIPLIER_RANGE.y)
	hunter.salary = hunter.expected_salary()
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


#직업 / 전직
## 그 레벨이면 몇 티어까지 전직 가능한지. 제때 전직했다고 볼 때의 티어다.
static func tier_for_level(target_level: int) -> int:
	var reached := grade_for_level(target_level)
	var tier := Job.MIN_TIER
	for i in range(1, TIER_GRADES.size()):
		if reached >= TIER_GRADES[i]:
			tier = i + 1
	return tier


## 지금 등급이 다음 티어 전직 조건을 만족하는가.
func can_promote() -> bool:
	return Job.can_promote(job_tier) and grade >= TIER_GRADES[job_tier]


## 전직. 등급 조건을 만족하면 gain_experience()가 알아서 부른다.
func promote() -> bool:
	if not can_promote():
		return false
	job_tier += 1
	return true


## 다음 티어 전직에 필요한 등급. 3차면 현재 등급을 그대로 돌려준다.
func next_promotion_grade() -> Grade:
	if not Job.can_promote(job_tier):
		return grade
	return TIER_GRADES[job_tier]


## 현재 언어로 된 직업 이름.
func job_display_name() -> String:
	return Job.display_name(job_line, job_tier, hunter_gender == Gender.FEMALE)


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
	# 전직 조건이 등급이라 등급이 오른 시점에만 확인하면 된다.
	# 한 번에 여러 등급을 뛰어넘어도 while이 티어를 따라잡는다.
	while promote():
		pass
	if grade != previous_grade:
		grade_changed.emit(grade)
	return leveled_up


## 성장률은 직업 계열에서 나온다. 티어와는 무관하다.
func _apply_growth(times: int) -> void:
	if times <= 0:
		return
	var growth := Job.growth(job_line)
	health += growth.health * times
	strength += growth.strength * times
	agility += growth.agility * times
	mana += growth.mana * times


#길드 운영
## 등급 기준가. 개인차가 붙기 전의 밸런스 기준선이다.
static func base_salary(target_grade: Grade) -> int:
	return BASE_SALARIES[target_grade]


## 실제로 매달 나가는 돈. 계약 금액이 그대로 나간다.
func monthly_salary() -> int:
	return salary


## 지금 등급과 몸값 배율로 계산한 금액. 모집 시 계약액의 기준이 된다.
func expected_salary() -> int:
	return int(base_salary(grade) * salary_multiplier)


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
