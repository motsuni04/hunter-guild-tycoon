extends MeshInstance3D

# 회전 속도 (초당 라디안 단위)
@export var rotation_speed: float = 14.7

func _process(delta: float):
	# Y축을 기준으로 매 프레임 회전
	# delta를 곱해주어야 프레임 드랍과 상관없이 일정한 속도로 회전합니다.
	rotate_y(rotation_speed * delta)
