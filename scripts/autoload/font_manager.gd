extends Node
## 폰트 테스트용 오토로드. 씬마다 개별 지정된 theme_override_fonts/font를
## 런타임에 강제로 덮어써서, 프로젝트 기본 테마만으로는 닿지 않는
## 기존 오버라이드까지 전부 바꾼다.
##
## 새로 생성되는 노드는 node_added에서 자동으로 현재 폰트를 적용받으므로,
## 동적으로 UI를 만드는 곳(tech_tree 등)도 별도 호출 없이 반영된다.

enum Choice { DEFAULT, SUIT, WANTED_SANS }

const FONT_PATHS := {
	Choice.DEFAULT: "res://assets/fonts/MonaS10.ttf",
	Choice.SUIT: "res://assets/fonts/SUIT-Variable.ttf",
	Choice.WANTED_SANS: "res://assets/fonts/WantedSansVariable.ttf",
}

const FONT_LABELS := {
	Choice.DEFAULT: "기본 (Mona)",
	Choice.SUIT: "SUIT",
	Choice.WANTED_SANS: "원티드 산스",
}

## 가변 폰트는 축을 지정하지 않으면 기본값(대개 최저 굵기)으로 렌더링된다.
## wght 축을 Regular로 고정한다. 가변 폰트가 아닌 경우엔 무시되는 값이라
## 모든 폰트에 동일하게 적용해도 무방하다.
const REGULAR_WEIGHT := 500.0

## 텍스트를 그리는 컨트롤 중 "font" 테마 항목을 갖는 타입들.
## 클래스 참조는 상수식으로 취급되지 않으므로 const가 아닌 var로 둔다.
var _text_control_types: Array = [Label, Button, RichTextLabel, LineEdit, OptionButton, TextEdit]

signal font_changed(choice: Choice)

var current: Choice = Choice.DEFAULT
var current_font: Font


func _ready() -> void:
	current_font = _load_font(current)
	get_tree().node_added.connect(_on_node_added)


func set_font(choice: Choice) -> void:
	if choice == current:
		return
	current = choice
	current_font = _load_font(choice)
	_apply_recursive(get_tree().root)
	font_changed.emit(choice)


func _load_font(choice: Choice) -> Font:
	var base := load(FONT_PATHS[choice]) as Font
	var variation := FontVariation.new()
	variation.base_font = base

	# 가변 폰트가 축을 다른 이름으로 노출하거나, wght 범위가 400/500을
	# 포함하지 않을 수 있으므로 실제 축 목록을 확인하고 범위 안으로 clamp한다.
	var axes: Dictionary = base.get_supported_variation_list()
	if axes.is_empty():
		print("[FontManager] %s: 가변 축을 찾지 못했습니다 (정적 폰트이거나 임포트 문제)." % FONT_LABELS[choice])
	else:
		print("[FontManager] %s 가변 축: %s" % [FONT_LABELS[choice], axes])

	# 콜론 없는 var: Variant를 반환하는 함수라 타입 추론 경고를 피하려면
	# ":="가 아니라 아예 타입 표기 없는 대입을 써야 한다.
	var wght_tag = _find_axis_tag(axes, "wght")
	if wght_tag == null:
		if not axes.is_empty():
			print("[FontManager] %s: wght 축이 없습니다. 사용 가능한 축만 표시됩니다." % FONT_LABELS[choice])
	else:
		var axis_range: Vector3 = axes[wght_tag]
		var weight: float = clampf(REGULAR_WEIGHT, axis_range.x, axis_range.y)
		variation.variation_opentype = {wght_tag: weight}
		print("[FontManager] %s wght=%s (요청 %s, 허용 범위 %s~%s)" % [
			FONT_LABELS[choice], weight, REGULAR_WEIGHT, axis_range.x, axis_range.y])

	return variation


## get_supported_variation_list()의 키가 문자열 태그인지 패킹된 정수 태그인지
## Godot 버전에 따라 다를 수 있어 양쪽 다 처리한다.
## 찾지 못하면 null. 키가 정수일 수 있으므로 빈 문자열을 센티널로 쓰면 안 된다.
func _find_axis_tag(axes: Dictionary, tag_name: String) -> Variant:
	for key in axes:
		if typeof(key) == TYPE_STRING or typeof(key) == TYPE_STRING_NAME:
			if String(key) == tag_name:
				return key
		elif typeof(key) == TYPE_INT:
			if _int_tag_to_string(key) == tag_name:
				return key
	return null


## OpenType 축 태그는 4바이트를 정수로 패킹한 형태로 오기도 한다 (예: 'wght').
func _int_tag_to_string(tag: int) -> String:
	var chars := PackedByteArray()
	for shift in [24, 16, 8, 0]:
		chars.append((tag >> shift) & 0xFF)
	return chars.get_string_from_ascii()


func _on_node_added(node: Node) -> void:
	_apply_to(node)


func _apply_recursive(node: Node) -> void:
	_apply_to(node)
	for child in node.get_children():
		_apply_recursive(child)


func _apply_to(node: Node) -> void:
	for type in _text_control_types:
		if is_instance_of(node, type):
			node.add_theme_font_override("font", current_font)
			return
