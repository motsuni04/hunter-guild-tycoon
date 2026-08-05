class_name Party
extends Resource

## 던전에 파견하는 헌터 파티. 파티 편성 화면의 한 줄에 대응한다.

const MAX_MEMBERS := 4

@export var party_id: int = 1
@export var members: Array[Hunter] = []
## 던전에 나가 있는 동안은 편성을 바꿀 수 없다.
@export var is_dispatched: bool = false


func display_name() -> String:
	return "%d팀" % party_id


func member_count() -> int:
	return members.size()


func is_full() -> bool:
	return members.size() >= MAX_MEMBERS


func is_empty() -> bool:
	return members.is_empty()


func has_member(hunter: Hunter) -> bool:
	return members.has(hunter)


func add_member(hunter: Hunter) -> bool:
	if hunter == null or is_dispatched or is_full() or has_member(hunter):
		return false
	members.append(hunter)
	return true


func remove_member(hunter: Hunter) -> bool:
	if is_dispatched or not has_member(hunter):
		return false
	members.erase(hunter)
	return true


func clear_members() -> void:
	if is_dispatched:
		return
	members.clear()


func total_power() -> int:
	var power := 0
	for hunter in members:
		power += hunter.attack + hunter.defense + hunter.max_hp / 10
	return power
