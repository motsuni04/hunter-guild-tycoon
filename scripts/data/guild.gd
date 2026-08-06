class_name Guild
extends Resource

## 플레이어가 운영하는 길드. 세이브 파일의 최상위 데이터이기도 하다.

signal gold_changed(gold: int)
signal hunters_changed()
signal date_changed(year: int, month: int, day: int)
## 달이 바뀔 때. 월급 지급 같은 월 단위 처리의 신호로 쓴다.
signal month_passed(year: int, month: int)
## 월급을 치른 뒤. in_debt면 지급 결과 자금이 마이너스로 떨어진 것이다.
signal salaries_paid(total: int, in_debt: bool)
## 자금이 0 이상에서 마이너스로 떨어진 순간. 경고 연출용.
signal fell_into_debt(gold: int)

const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12
const PARTY_COUNT := 5

@export var guild_name: String = "플레이어 길드"
## 자발적 지출(spend)로는 0 미만이 될 수 없지만, 월급 같은 고정 지출은 마이너스를 만든다.
@export var gold: int = 0:
	set(value):
		if value == gold:
			return
		var was_solvent := gold >= 0
		gold = value
		gold_changed.emit(gold)
		if was_solvent and gold < 0:
			fell_into_debt.emit(gold)
@export var member_capacity: int = 20

@export_group("날짜")
@export var year: int = 1
@export var month: int = 1
@export var day: int = 1

@export_group("보유 데이터")
@export var hunters: Array[Hunter] = []
@export var parties: Array[Party] = []
## 시설 이름 -> 건설 레벨. 없으면 미건설.
@export var facility_levels: Dictionary = {}
@export var researched_techs: Array[String] = []

@export var next_hunter_id: int = 1


#표시용
func date_text() -> String:
	return "%d년차 %d월 %d일" % [year, month, day]


func gold_text() -> String:
	return format_gold(gold)


func member_text() -> String:
	return "%d/%d" % [member_count(), member_capacity]


## 1780 -> "1,780". 금액 단위(만원)는 붙이는 쪽에서 처리한다.
static func format_gold(amount: int) -> String:
	var digits := str(absi(amount))
	var text := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			text += ","
		text += digits[i]
	return ("-" if amount < 0 else "") + text


#헌터
func member_count() -> int:
	return hunters.size()


func is_full() -> bool:
	return hunters.size() >= member_capacity


func add_hunter(hunter: Hunter) -> bool:
	if hunter == null or is_full() or hunters.has(hunter):
		return false
	if hunter.hunter_id == 0:
		hunter.hunter_id = next_hunter_id
		next_hunter_id += 1
	hunters.append(hunter)
	hunters_changed.emit()
	return true


## 파티에서도 함께 빼낸다.
func remove_hunter(hunter: Hunter) -> bool:
	if not hunters.has(hunter):
		return false
	hunters.erase(hunter)
	for party in parties:
		party.members.erase(hunter)
	hunters_changed.emit()
	return true


func find_hunter(hunter_id: int) -> Hunter:
	for hunter in hunters:
		if hunter.hunter_id == hunter_id:
			return hunter
	return null


## 어느 파티에도 속하지 않은 헌터들.
func idle_hunters() -> Array[Hunter]:
	var result: Array[Hunter] = []
	for hunter in hunters:
		if find_party_of(hunter) == null:
			result.append(hunter)
	return result


#파티
func setup_parties() -> void:
	parties.clear()
	for i in PARTY_COUNT:
		var party := Party.new()
		party.party_id = i + 1
		parties.append(party)


func get_party(party_id: int) -> Party:
	for party in parties:
		if party.party_id == party_id:
			return party
	return null


func find_party_of(hunter: Hunter) -> Party:
	for party in parties:
		if party.has_member(hunter):
			return party
	return null


#자금
func can_afford(amount: int) -> bool:
	return gold >= amount


func is_in_debt() -> bool:
	return gold < 0


## 건설·제작·모집처럼 플레이어가 고르는 지출. 전액을 못 내면 아무것도 쓰지 않고 false.
func spend(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	gold -= amount
	return true


## 월급처럼 거부할 수 없는 지출. 자금이 모자라면 마이너스가 된다.
func pay_fixed_cost(amount: int) -> void:
	if amount <= 0:
		return
	gold -= amount


func earn(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount


#날짜
func advance_day(days: int = 1) -> void:
	if days <= 0:
		return
	day += days
	# 한 번에 여러 달을 건너뛰어도 월 단위 처리가 빠지지 않도록 넘긴 달을 모아둔다.
	var crossed_months: Array[Vector2i] = []
	while day > DAYS_PER_MONTH:
		day -= DAYS_PER_MONTH
		month += 1
		if month > MONTHS_PER_YEAR:
			month -= MONTHS_PER_YEAR
			year += 1
		crossed_months.append(Vector2i(year, month))
	date_changed.emit(year, month, day)
	for entry in crossed_months:
		month_passed.emit(entry.x, entry.y)


#월급
func total_salary() -> int:
	var total := 0
	for hunter in hunters:
		total += hunter.monthly_salary()
	return total


## 전원에게 월급을 지급한다. 자금이 모자라도 전액을 지급하고 그만큼 마이너스가 된다.
func pay_salaries() -> int:
	var total := total_salary()
	pay_fixed_cost(total)
	salaries_paid.emit(total, is_in_debt())
	return total


#시설 / 연구
func facility_level(facility_name: String) -> int:
	return facility_levels.get(facility_name, 0)


func upgrade_facility(facility_name: String) -> int:
	var level: int = facility_level(facility_name) + 1
	facility_levels[facility_name] = level
	return level


func has_researched(tech_name: String) -> bool:
	return researched_techs.has(tech_name)


func research(tech_name: String) -> bool:
	if has_researched(tech_name):
		return false
	researched_techs.append(tech_name)
	return true
