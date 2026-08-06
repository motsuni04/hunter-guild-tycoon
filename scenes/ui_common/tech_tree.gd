extends VBoxContainer
## 기술 데이터를 읽어 티어별로 배치하고, 선행 관계를 연결선으로 그린다.
##
## 연결선은 별도 레이어가 아니라 이 컨테이너의 _draw()에서 그린다.
## Godot은 부모를 자식보다 먼저 그리므로 선이 자연히 노드 뒤에 깔린다.

const TECH_DIR := "res://resources/tech/"

const LINE_COLOR := Color(0.85, 0.15, 0.15)
const LINE_WIDTH := 3.0
const TIER_SEPARATION := 80
const NODE_SEPARATION := 40

## Tech -> TechNode
var _node_by_tech := {}

signal tech_selected(tech: Tech)


func _ready() -> void:
	add_theme_constant_override("separation", TIER_SEPARATION)
	_build(_load_techs())
	# 컨테이너 배치는 프레임 끝에 확정되므로 배치가 끝난 뒤 다시 그린다.
	sort_children.connect(queue_redraw)
	resized.connect(queue_redraw)


func _load_techs() -> Array[Tech]:
	var techs: Array[Tech] = []
	var dir := DirAccess.open(TECH_DIR)
	if dir == null:
		push_error("기술 데이터 폴더를 열 수 없습니다: " + TECH_DIR)
		return techs

	for file_name in dir.get_files():
		# 내보낸 빌드에서는 .remap 확장자가 붙는다.
		var path := TECH_DIR + file_name.trim_suffix(".remap")
		if not path.ends_with(".tres"):
			continue
		var tech := load(path) as Tech
		if tech == null:
			push_warning("기술 리소스를 읽지 못했습니다: " + path)
			continue
		techs.append(tech)

	return techs


func _build(techs: Array[Tech]) -> void:
	_node_by_tech.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var by_tier := {}
	for tech in techs:
		if not by_tier.has(tech.tier):
			by_tier[tech.tier] = []
		by_tier[tech.tier].append(tech)

	var tiers := by_tier.keys()
	tiers.sort()

	# 상위 티어부터 순서를 확정하고, 그 순서를 기준으로 하위 티어를 정렬한다.
	var previous_order: Array = []
	for tier in tiers:
		var ordered := _order_tier(by_tier[tier], previous_order)

		var row := _make_row()
		for tech in ordered:
			var node := TechNode.create(tech)
			node.pressed.connect(_on_tech_pressed.bind(tech))
			row.add_child(node)
			_node_by_tech[tech] = node
		add_child(row)

		previous_order = ordered


## 선행 기술들의 평균 위치(무게중심)를 기준으로 정렬해 연결선이 교차하지 않게 한다.
func _order_tier(group: Array, previous_order: Array) -> Array:
	var entries := []
	for tech in group:
		entries.append({"tech": tech, "key": _barycenter(tech, previous_order)})

	entries.sort_custom(func(a, b):
		if a["key"] != b["key"]:
			return a["key"] < b["key"]
		return a["tech"].tech_id < b["tech"].tech_id)

	var ordered := []
	for entry in entries:
		ordered.append(entry["tech"])
	return ordered


func _barycenter(tech: Tech, previous_order: Array) -> float:
	var total := 0.0
	var count := 0
	for requirement in tech.requirements:
		var index := previous_order.find(requirement)
		if index != -1:
			total += index
			count += 1
	if count == 0:
		# 선행 기술이 없으면 순서를 정할 근거가 없으므로 뒤로 보내고 tech_id로 정렬한다.
		return INF
	return total / count


func _make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", NODE_SEPARATION)
	return row


func _draw() -> void:
	var links := _collect_links()
	var lanes := _assign_lanes(links)
	for link in links:
		_draw_link(link["start"], link["end"], lanes[link["parent"]])


## 그릴 연결선의 시작점과 끝점을 미리 계산한다.
## 선행 기술이 여럿인 기술은 진입 지점을 위쪽 변에 나눠 준다.
## 한 점으로 모으면 마지막 세로 구간이 완전히 겹쳐 한 줄로 보인다.
func _collect_links() -> Array:
	# Control에는 to_local()이 없으므로 전역 좌표를 직접 이 컨테이너 기준으로 옮긴다.
	var inv_transform := get_global_transform().affine_inverse()
	var links := []

	for tech in _node_by_tech:
		var parents := []
		for requirement in tech.requirements:
			if _node_by_tech.has(requirement):
				parents.append(requirement)
		if parents.is_empty():
			continue

		# 부모를 가로 위치 순으로 정렬해야 진입 지점이 서로 엇갈리지 않는다.
		parents.sort_custom(func(a, b):
			return _node_by_tech[a].global_position.x < _node_by_tech[b].global_position.x)

		var child: Control = _node_by_tech[tech]
		var child_rect := Rect2(inv_transform * child.global_position, child.size)

		for index in parents.size():
			var parent_node: Control = _node_by_tech[parents[index]]
			var parent_rect := Rect2(inv_transform * parent_node.global_position, parent_node.size)
			var ratio := float(index + 1) / float(parents.size() + 1)
			links.append({
				"parent": parents[index],
				"start": Vector2(parent_rect.get_center().x, parent_rect.end.y),
				"end": Vector2(
					lerpf(child_rect.position.x, child_rect.end.x, ratio),
					child_rect.position.y,
				),
			})

	return links


## 기술마다 가로줄 높이를 나눠 준다. 같은 높이면 여러 선이 한 줄로 뭉쳐 보인다.
## 가장 멀리 뻗는 연결을 부모 쪽에 붙여, 짧은 연결이 그 아래를 곧게 지나가게 한다.
func _assign_lanes(links: Array) -> Dictionary:
	var reach := {}
	for link in links:
		var width: float = absf(link["end"].x - link["start"].x)
		var parent = link["parent"]
		reach[parent] = maxf(reach.get(parent, 0.0), width)

	# 높이는 티어 사이 간격을 나눠 쓰는 값이므로 같은 티어끼리만 순위를 매긴다.
	var by_tier := {}
	for parent in reach:
		if not by_tier.has(parent.tier):
			by_tier[parent.tier] = []
		by_tier[parent.tier].append(parent)

	var lanes := {}
	for tier in by_tier:
		var parents: Array = by_tier[tier]
		parents.sort_custom(func(a, b): return reach[a] > reach[b])
		for index in parents.size():
			lanes[parents[index]] = float(index + 1) / float(parents.size() + 1)
	return lanes


func _draw_link(start: Vector2, end: Vector2, lane: float) -> void:
	var mid_y := lerpf(start.y, end.y, lane)
	var points := PackedVector2Array([
		start,
		Vector2(start.x, mid_y),
		Vector2(end.x, mid_y),
		end,
	])
	draw_polyline(points, LINE_COLOR, LINE_WIDTH)


func _on_tech_pressed(tech: Tech) -> void:
	tech_selected.emit(tech)
