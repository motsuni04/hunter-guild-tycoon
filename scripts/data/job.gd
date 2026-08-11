class_name Job
extends RefCounted

## 헌터의 직업. 8개 계열 × 3티어 = 24개.
## 전직은 "같은 계열의 다음 티어"라서 전직 대상을 따로 적지 않고 계산한다.
##
## 표시 이름은 여기에 없다. 번역 CSV(assets/translations/jobs.csv)가 들고 있고,
## 계열 id와 티어로 키를 만들어 조회한다. ("warrior", 2) -> "JOB_WARRIOR_2"
##
## 객체를 만들 일이 없어서 Resource가 아니다. 헌터는 계열 id와 티어만 저장하고
## 나머지는 전부 여기 static 함수로 조회한다.

enum Role { TANK, MELEE, RANGED, SUPPORT }

const MIN_TIER := 1
const MAX_TIER := 3

## 계열 8개. growth는 레벨업 1회당 상승치이며 티어와 무관하다.
## 전직은 스킬 해금으로 보상하고, 성장률은 계열 하나당 하나로 단순하게 둔다.
## 계열 간 균형은 "체력/4 + 근력 + 민첩 + 마력 = 12"로 맞춰 두었다.
## 이 총합을 유지하면 특정 계열이 상위호환이 되지 않는다.
const LINES := {
	"warrior":   {"role": Role.TANK,    "main_stat": "strength",
				  "growth": {"health": 24, "strength": 5, "agility": 1, "mana": 0}},
	"fighter":   {"role": Role.TANK,    "main_stat": "agility",
				  "growth": {"health": 24, "strength": 1, "agility": 5, "mana": 0}},
	"swordsman": {"role": Role.MELEE,   "main_stat": "strength",
				  "growth": {"health": 12, "strength": 7, "agility": 2, "mana": 0}},
	"rogue":     {"role": Role.MELEE,   "main_stat": "agility",
				  "growth": {"health": 12, "strength": 2, "agility": 7, "mana": 0}},
	"archer":    {"role": Role.RANGED,  "main_stat": "agility",
				  "growth": {"health": 8,  "strength": 2, "agility": 8, "mana": 0}},
	"mage":      {"role": Role.RANGED,  "main_stat": "mana",
				  "growth": {"health": 8,  "strength": 0, "agility": 2, "mana": 8}},
	"mystic":    {"role": Role.SUPPORT, "main_stat": "mana",
				  "growth": {"health": 12, "strength": 0, "agility": 3, "mana": 6}},
	"priest":    {"role": Role.SUPPORT, "main_stat": "mana",
				  "growth": {"health": 16, "strength": 0, "agility": 1, "mana": 7}},
}

## 성별에 따라 이름이 갈리는 (계열 -> 티어 목록).
## 여기 없으면 성별과 무관하게 같은 이름을 쓴다.
const GENDERED_NAMES := {
	"priest": [3],
}


static func lines() -> Array:
	return LINES.keys()


static func role(line: String) -> Role:
	return LINES[line].role


static func main_stat(line: String) -> String:
	return LINES[line].main_stat


## 레벨업 1회당 오르는 능력치.
static func growth(line: String) -> Dictionary:
	return LINES[line].growth


#전직
static func can_promote(tier: int) -> bool:
	return tier < MAX_TIER


#이름
## 번역 키. 실제 문자열은 번역 CSV가 들고 있다.
static func name_key(line: String, tier: int, is_female: bool = false) -> String:
	var key := "JOB_%s_%d" % [line.to_upper(), tier]
	if is_female and _has_gendered_name(line, tier):
		key += "_F"
	return key


## 현재 언어로 된 직업 이름. static이라 tr()을 못 쓰므로 TranslationServer를 직접 부른다.
static func display_name(line: String, tier: int, is_female: bool = false) -> String:
	return TranslationServer.translate(name_key(line, tier, is_female))


static func _has_gendered_name(line: String, tier: int) -> bool:
	return GENDERED_NAMES.has(line) and tier in GENDERED_NAMES[line]
