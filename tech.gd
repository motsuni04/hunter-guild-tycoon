class_name Tech
extends Resource

@export var tech_id: int
@export var tech_name: String
@export var icon: Texture2D
@export_multiline var description: String
## 연구시 필요로 하는 비용
@export var cost: int
## 기술 트리에서의 위치. 0부터 시작
@export var tier: int
## 연구하기 위해 필요한 기술. 항상 바로 이전 티어의 기술만 포함한다.
@export var requirements: Array[Tech]
## 상호 배타 관계인 기술. 이 중 하나라도 연구했다면 이 기술은 연구할 수 없다.
## .tres 순환 참조를 피하기 위해 관계마다 한쪽에만 등록하고,
## 판정은 conflicts_with()로 양방향 처리한다.
@export var conflicts: Array[Tech]


## 두 기술이 상호 배타 관계인지 반환한다.
func conflicts_with(other: Tech) -> bool:
	return other in conflicts or self in other.conflicts
