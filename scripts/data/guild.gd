class_name Guild
extends Resource

## 플레이어가 운영하는 길드. 세이브 파일의 최상위 데이터이기도 하다.

signal gold_changed(gold: int)
signal hunters_changed()
signal date_changed(year: int, month: int, day: int)

const DAYS_PER_MONTH := 30
const MONTHS_PER_YEAR := 12
const PARTY_COUNT := 5

@export var guild_name: String = "플레이어 길드"
@export var gold: int = 1780
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


func spend(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)


#날짜
func advance_day(days: int = 1) -> void:
	if days <= 0:
		return
	day += days
	while day > DAYS_PER_MONTH:
		day -= DAYS_PER_MONTH
		month += 1
		while month > MONTHS_PER_YEAR:
			month -= MONTHS_PER_YEAR
			year += 1
	date_changed.emit(year, month, day)


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
