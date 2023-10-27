extends TabContainer
# A simple extension for TabContainer that allows it to be disabled as a whole
# and in a way independent of its individual tabs being disabled or re-enabled.


var _manually_disabled = []
@onready var main_node = $"/root/Catapult/Main"
@onready var _tabs = ["tab_game", "tab_mods", "tab_soundpacks", "tab_fonts", "tab_backups", "tab_settings"]
@export var disabled: bool = false : set = _set_disabled

func _ready():
    for _tab_index in _tabs.size():
        set_tab_title(_tab_index, tr(_tabs[_tab_index]))

    if not Settings.read("debug_mode"):
        remove_child($DebugTab)

func _set_disabled(value: bool) -> void:
    
    for i in get_tab_count():
        if (value == true) and (i == current_tab):
            # https://github.com/godotengine/godot/issues/52290
            continue
        if not i in _manually_disabled:
            set_tab_disabled(i, value)
    
    disabled = value

@warning_ignore("native_method_override")
func set_tab_disabled(index: int, value: bool) -> void:
    
    if (value == true) and (not index in _manually_disabled):
        _manually_disabled.append(index)
    elif index in _manually_disabled:
        _manually_disabled.erase(index)
    
    if not disabled:
        super.set_tab_disabled(index, value)
