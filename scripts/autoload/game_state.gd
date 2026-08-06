extends Node

## 현재 진행 중인 게임 상태를 들고 있는 오토로드(GameState).
## UI는 Guild를 직접 구독하지 말고 이 노드의 시그널에 연결한다.
## 새 게임/불러오기로 Guild 인스턴스가 바뀌어도 연결이 끊기지 않는다.

signal gold_changed(gold: int)
signal hunters_changed()
signal date_changed(year: int, month: int, day: int)
## 새 게임이나 불러오기로 길드가 통째로 교체됐을 때. UI 전체 갱신용.
signal guild_changed(guild: Guild)
## 월급 지급 결과. in_debt면 지급 후 자금이 마이너스다.
signal salaries_paid(total: int, in_debt: bool)
## 자금이 마이너스로 떨어진 순간.
signal fell_into_debt(gold: int)

const SAVE_PATH := "user://savegame.tres"
const DEFAULT_GUILD_NAME := "플레이어 길드"

var guild: Guild


func _ready() -> void:
	if guild == null:
		new_game()


#게임 시작 / 세이브
func new_game(guild_name: String = DEFAULT_GUILD_NAME) -> void:
	var new_guild := Guild.new()
	new_guild.guild_name = guild_name
	new_guild.setup_parties()
	_set_guild(new_guild)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	if guild == null:
		return false
	var error := ResourceSaver.save(guild, SAVE_PATH)
	if error != OK:
		push_error("세이브 실패 (%d): %s" % [error, SAVE_PATH])
		return false
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var loaded := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	if loaded is not Guild:
		push_error("세이브 파일을 읽을 수 없습니다: %s" % SAVE_PATH)
		return false
	if loaded.parties.is_empty():
		loaded.setup_parties()
	_set_guild(loaded)
	return true


#진행
func advance_day(days: int = 1) -> void:
	if guild == null:
		return
	guild.advance_day(days)


#편의 접근자 (UI에서 GameState.gold 처럼 쓰기 위한 것)
var gold: int:
	get: return guild.gold if guild else 0

var member_count: int:
	get: return guild.member_count() if guild else 0

var member_capacity: int:
	get: return guild.member_capacity if guild else 0


func date_text() -> String:
	return guild.date_text() if guild else ""


func gold_text() -> String:
	return guild.gold_text() if guild else "0"


func member_text() -> String:
	return guild.member_text() if guild else "0/0"


#내부
func _set_guild(new_guild: Guild) -> void:
	if guild != null:
		guild.gold_changed.disconnect(_on_gold_changed)
		guild.hunters_changed.disconnect(_on_hunters_changed)
		guild.date_changed.disconnect(_on_date_changed)
		guild.month_passed.disconnect(_on_month_passed)
		guild.salaries_paid.disconnect(_on_salaries_paid)
		guild.fell_into_debt.disconnect(_on_fell_into_debt)
	guild = new_guild
	guild.gold_changed.connect(_on_gold_changed)
	guild.hunters_changed.connect(_on_hunters_changed)
	guild.date_changed.connect(_on_date_changed)
	guild.month_passed.connect(_on_month_passed)
	guild.salaries_paid.connect(_on_salaries_paid)
	guild.fell_into_debt.connect(_on_fell_into_debt)

	guild_changed.emit(guild)
	gold_changed.emit(guild.gold)
	hunters_changed.emit()
	date_changed.emit(guild.year, guild.month, guild.day)


func _on_gold_changed(value: int) -> void:
	gold_changed.emit(value)


func _on_hunters_changed() -> void:
	hunters_changed.emit()


func _on_date_changed(year: int, month: int, day: int) -> void:
	date_changed.emit(year, month, day)


## 월급 지급 시점은 헌터 한 명만 봐서는 알 수 없으므로 여기서 처리한다.
func _on_month_passed(_year: int, _month: int) -> void:
	guild.pay_salaries()


func _on_salaries_paid(total: int, in_debt: bool) -> void:
	salaries_paid.emit(total, in_debt)


func _on_fell_into_debt(value: int) -> void:
	fell_into_debt.emit(value)
