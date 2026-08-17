class_name TechNode
extends Button
## 테크트리에 표시되는 기술 한 칸.

const FONT := preload("res://assets/fonts/MonaS10.ttf")
const PLACEHOLDER_ICON := preload("res://assets/images/tech_empty.png")
const PANEL_STYLE := preload("res://resources/ui/info_panel.tres")

const NODE_SIZE := Vector2(180, 210)
const ICON_SIZE := Vector2(96, 96)

var tech: Tech


static func create(p_tech: Tech) -> TechNode:
	var node := TechNode.new()
	node.tech = p_tech
	return node


func _ready() -> void:
	custom_minimum_size = NODE_SIZE
	# 상태별 색 구분은 연구 가능/완료 로직이 붙을 때 나눈다. 지금은 전부 같은 스타일.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, PANEL_STYLE)
	if tech == null:
		return
	tooltip_text = tech.description
	_build()


func _build() -> void:
	# Button은 Container가 아니라 자식 크기를 따라가지 않는다.
	# 전체 앵커로 붙여 버튼 크기를 그대로 따르게 한다.
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var icon_rect := TextureRect.new()
	icon_rect.texture = tech.icon if tech.icon else PLACEHOLDER_ICON
	icon_rect.custom_minimum_size = ICON_SIZE
	# 기본값은 텍스처 원본 크기가 최소 크기를 강제하므로 반드시 꺼야 한다.
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon_rect)

	box.add_child(_make_label(tech.tech_name, 24))
	box.add_child(_make_label("%d만원" % tech.cost, 18))


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
